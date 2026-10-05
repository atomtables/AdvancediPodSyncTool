//
//  STConfigWindowController.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 4/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <EventKit/EventKit.h>
#import <Cocoa/Cocoa.h>

@interface STTableCellView: NSTableCellView
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField* label;
@end


@interface AccountsTableController : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, copy) void (^onSelectionChanged)(EKSource* selectedAccountIndex);
@property (unsafe_unretained) NSTableView* tableView;
@property (nonatomic, copy) NSString *deviceSerialNumber;
@property (nonatomic, copy) void (^onAccountToggled)(EKSource *account);
@end


@interface CalendarsTableController : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) NSArray *calendars;
@property (nonatomic, copy) void (^onSelectionChanged)(long selectedAccountIndex);
@property (unsafe_unretained) NSTableView* tableView;
@property (nonatomic, copy) NSString *deviceSerialNumber;
@property (nonatomic, copy) void (^onCalendarToggled)(EKCalendar *calendar);
@end

@interface STConfigWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, unsafe_unretained) IBOutlet NSScrollView* scrollView;
@property (nonatomic, unsafe_unretained) IBOutlet NSView* mainiPodView;

#pragma mark - Subview outlets

@property (nonatomic, unsafe_unretained) IBOutlet NSImageView* ipodIcon;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField* ipodName;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField* ipodDetails;

@property (nonatomic, unsafe_unretained) IBOutlet NSButton* syncCalendarButton;

@property (unsafe_unretained) IBOutlet NSTableView *accountsTableView;
@property (unsafe_unretained) IBOutlet NSTableView *calendarsTableView;

@property (strong) AccountsTableController *accountsController;
@property (strong) CalendarsTableController *calendarsController;

@end

