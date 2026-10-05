//
//  AppDelegate.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "AppDelegate.h"
#import "STCalendarEventsProvider.h"

@interface AppDelegate ()



@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.watcher = [[STiPodWatcher alloc] init];
    // Insert code here to initialize your application
    
    self.calendarProvider = [[STCalendarCurrentEventsProvider alloc] init];
    NSLog(@"calendarAccessProvided:%d", [self.calendarProvider calendarAccessProvided]);
    if ([self.calendarProvider calendarAccessProvided]) {
        NSLog(@"eventCount as shown: %ld", [self.calendarProvider totalEventCount]);
        NSLog(@"events: %@", [self.calendarProvider allEvents]);
    };
    if ([self.calendarProvider reminderAccessProvided]) {
        NSLog(@"reminderCount as shown: %ld", [self.calendarProvider totalReminderCount]);
        NSLog(@"reminders: %@", [self.calendarProvider allReminders]);
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
