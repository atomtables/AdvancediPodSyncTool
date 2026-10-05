//
//  STStatusBarController.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "STConfigWindowController.h"
#import "STStatusBarController.h"
#import "AppDelegate.h"

@implementation STStatusBarController {
    NSWindowController* currentlyOpenViewController;
}

- (void)awakeFromNib {
    [self instantiateMenuBar];
    currentlyOpenViewController = [[STConfigWindowController alloc] initWithWindowNibName:@"STConfigWindowController"];
}

- (void)instantiateMenuBar {
    NSStatusBar* bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    
    NSImage* image = [NSImage imageNamed:@"NSSlideshowTemplate"];
    [self.statusItem setImage:image];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];
    
    
    
    [self.menu setDelegate:self];
}

- (IBAction)openCalendarWindow:(id)sender {
//    currentlyOpenViewController = [[STCalendarConfigController alloc] initWithNibName:@"STCalendarConfigController" bundle:nil];
//    [[currentlyOpenViewController view] setFrame:[[self.window contentView] bounds]];
//    [self.window setContentView:currentlyOpenViewController.view];
//    [self.window makeKeyAndOrderFront:nil];
    [[currentlyOpenViewController window] makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:true];
}

- (void)menuNeedsUpdate:(NSMenu*)menu {
    int initialCount = (int)[menu numberOfItems];
    for (int i = 0; i < initialCount; i++) {
        if ([[menu itemAtIndex:i] isSeparatorItem]) break;
        [menu removeItemAtIndex:i];
        i--; initialCount--;
    }
    
    // get dict
    NSDictionary* devicesDict = [[(AppDelegate*)[NSApp delegate] watcher] connectedDevices];
    int i = 0;
    for (NSString* deviceId in devicesDict) {
        NSDictionary* device = devicesDict[deviceId];
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%04x:%04x %@ %@",
                                                              [device[@"vendorId"] intValue],
                                                              [device[@"productId"] intValue],
                                                              device[@"vendorName"],
                                                              device[@"productName"]]
                                                      action:nil
                                               keyEquivalent:@""];
        [menu insertItem:item atIndex:i++];
    }
}

@end
