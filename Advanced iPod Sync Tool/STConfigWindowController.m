//
//  STConfigWindowController.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 4/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "AppDelegate.h"
#import "STiPodWatcher.h"
#import "STiPodDataStore.h"
#import "STiPodSyncExecutor.h"
#import "STConfigWindowController.h"

@implementation STTableCellView
@end

@interface STConfigWindowController ()

@end

@implementation STConfigWindowController {
    long selectedRow;
    EKSource* selectedCalendarAccount;
    NSDictionary* selectedDevice;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.scrollView setDocumentView:self.mainiPodView];
}

- (IBAction)synciPod:(id)sender {
    [STiPodSyncExecutor syncAllOntoiPod:selectedDevice[@"serialNumber"]];
}

- (void)initTheTables {
    self.accountsController = [[AccountsTableController alloc] init];
    self.accountsController.accounts = [[[NSApp delegate] calendarProvider] allAccounts];
    self.accountsTableView.delegate = self.accountsController;
    self.accountsTableView.dataSource = self.accountsController;
    __unsafe_unretained typeof(self) weakSelf = self;
    self.accountsController.onSelectionChanged = ^(EKSource* changed) {
        NSLog(@"recieved change in accounts controller: %@", changed);
        weakSelf->selectedCalendarAccount = changed;
        [weakSelf.calendarsTableView setHidden:false];
        [weakSelf.calendarsController setCalendars:[[[NSApp delegate] calendarProvider] calendarsForAccount:changed]];
    };
    self.accountsController.tableView = self.accountsTableView;
    self.accountsController.deviceSerialNumber = selectedDevice[@"serialNumber"];
    
    self.calendarsController = [[CalendarsTableController alloc] init];
    [self.calendarsTableView setHidden:true];
    self.calendarsTableView.delegate = self.calendarsController;
    self.calendarsTableView.dataSource = self.calendarsController;
    self.calendarsController.tableView = self.calendarsTableView;
    self.calendarsController.onSelectionChanged = ^(long changed) {
        NSLog(@"recieved change in calendars controller: %ld", changed);
    };
    self.calendarsController.deviceSerialNumber = selectedDevice[@"serialNumber"];
}

#pragma mark - TableViewDelegate
- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary* devices = [[[NSApp delegate] watcher] connectedDevices];
    NSArray* keys = [devices allKeys];
    NSDictionary* device = devices[keys[row]];
    
    STTableCellView* view = [tableView makeViewWithIdentifier:@"col1" owner:self];
    view.imageView.image = [[NSImage alloc] initByReferencingFile:[NSString stringWithFormat:@"%@/.VolumeIcon.icns", [device[@"mountPoint"] path]]];
    [view.textField setStringValue:device[@"name"]];
    [view.label setStringValue:device[@"serialNumber"]];
    return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableView = [notification object];
    selectedRow = [tableView selectedRow];
    NSDictionary* devices = [[[NSApp delegate] watcher] connectedDevices];
    NSArray* keys = [devices allKeys];
    selectedDevice = devices[keys[selectedRow]];
    [self initTheTables];
}

#pragma mark - TableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[[NSApp delegate] watcher] connectedDevices] count];
}

@end

#pragma mark - Auxiliary tables

@interface AccountsTableController ()

@end

@implementation AccountsTableController {
    
}

- (void)setAccounts:(NSArray *)accounts {
    _accounts = accounts;
    [self.tableView reloadData];
}

- (int)stateForAccount:(EKSource *)account {
    if (!self.deviceSerialNumber || !account) return NSOffState;
    
    NSArray *calendars = [[[NSApp delegate] calendarProvider] calendarsForAccount:account];
    if (calendars.count == 0) return NSOffState;
    
    NSMutableSet *selectedIDs = [STiPodDataStore selectedCalendarIDsForDevice:self.deviceSerialNumber];
    NSInteger selectedCount = 0;
    
    for (EKCalendar *cal in calendars) {
        if ([selectedIDs containsObject:cal.calendarIdentifier]) {
            selectedCount++;
        }
    }
    
    if (selectedCount == 0) {
        return NSOffState;
    } else if (selectedCount == calendars.count) {
        return NSOnState;
    } else {
        return NSMixedState;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualToString:@"toggle"]) {
        NSButton *checkbox = [tableView makeViewWithIdentifier:@"toggle" owner:self];
        checkbox.state = [self stateForAccount:[self accounts][row]];
        
        checkbox.target = self;
        checkbox.action = @selector(checkboxToggled:);
        
        return checkbox;
    } else if ([tableColumn.identifier isEqualToString:@"item"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"item" owner:self];
        
        cellView.textField.stringValue = [[self accounts][row] title];
        
        return cellView;
    }
    
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableView = [notification object];
    self.onSelectionChanged(self.accounts[[tableView selectedRow]]);
}

- (IBAction)checkboxToggled:(id)sender {
    NSButton *checkbox = (NSButton *)sender;
    NSInteger row = [self.tableView rowForView:checkbox];
    if (row < 0 || row >= self.accounts.count) return;
    
    EKSource *account = self.accounts[row];
    NSArray* calendars = [[[NSApp delegate] calendarProvider] calendarsForAccount:account];
    NSMutableSet *selectedIDs = [STiPodDataStore selectedCalendarIDsForDevice:self.deviceSerialNumber];
    
    int currentState = [self stateForAccount:account];
    BOOL shouldSelectAll = (currentState == NSOffState);
    
    for (EKCalendar *cal in calendars) {
        if (shouldSelectAll) {
            [selectedIDs addObject:cal.calendarIdentifier];
        } else {
            [selectedIDs removeObject:cal.calendarIdentifier];
        }
    }
    
    [STiPodDataStore setSelectedCalendarIDs:selectedIDs forDevice:self.deviceSerialNumber];
    [self.tableView reloadData];
    
    if (self.onAccountToggled) {
        self.onAccountToggled(account);
    }
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:false];
}

- (long)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self accounts] count];
}

@end

@implementation CalendarsTableController {
    
}

- (void)setCalendars:(NSArray *)calendars {
    _calendars = calendars;
    NSLog(@"recieved new update for calendars: %@", calendars);
    [self.tableView reloadData];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualToString:@"toggle"]) {
        NSButton *checkbox = [tableView makeViewWithIdentifier:@"toggle" owner:self];
        EKCalendar *calendar = self.calendars[row];
        NSMutableSet *selectedIDs = [STiPodDataStore selectedCalendarIDsForDevice:self.deviceSerialNumber];
        
        if ([selectedIDs containsObject:calendar.calendarIdentifier]) {
            checkbox.state = NSOnState;
        } else {
            checkbox.state = NSOffState;
        }
        
        checkbox.target = self;
        checkbox.action = @selector(checkboxToggled:);
        
        return checkbox;
    } else if ([tableColumn.identifier isEqualToString:@"item"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"item" owner:self];
        
        cellView.textField.stringValue = [[self calendars][row] title];
        
        return cellView;
    }
    
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableView = [notification object];
    self.onSelectionChanged([tableView selectedRow]);
}

- (IBAction)checkboxToggled:(id)sender {
    NSButton *checkbox = (NSButton *)sender;
    NSInteger row = [self.tableView rowForView:checkbox];
    if (row < 0 || row >= self.calendars.count) return;
    
    EKCalendar *calendar = self.calendars[row];
    NSMutableSet *selectedIDs = [STiPodDataStore selectedCalendarIDsForDevice:self.deviceSerialNumber];
    
    if ([selectedIDs containsObject:calendar.calendarIdentifier]) {
        [selectedIDs removeObject:calendar.calendarIdentifier];
    } else {
        [selectedIDs addObject:calendar.calendarIdentifier];
    }
    
    [STiPodDataStore setSelectedCalendarIDs:selectedIDs forDevice:self.deviceSerialNumber];
    [self.tableView reloadData];
    
    if (self.onCalendarToggled) {
        self.onCalendarToggled(calendar);
    }
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:false];
}

- (long)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self calendars] count];
}

@end
