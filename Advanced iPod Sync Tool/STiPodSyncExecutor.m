//
//  STiPodSyncExecutor.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 5/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "AppDelegate.h"
#import "STiPodDataStore.h"
#import "STiPodSyncExecutor.h"

@implementation STiPodSyncExecutor

+ (BOOL)syncAllOntoiPod:(NSString*)sn {
    NSError* error;
    NSURL* mountPath = [[[NSApp delegate] watcher] connectedDevices][sn][@"mountPoint"];
    NSLog(@"%@ %@ %@", [[[NSApp delegate] watcher] connectedDevices], [[[NSApp delegate] watcher] connectedDevices][sn], mountPath);
    NSURL* destinationURL = [NSURL URLWithString:@"Calendars" relativeToURL:mountPath];
    NSLog(@"%@", destinationURL);
    
    // get list of calendars
    NSArray *calendarIDs = [[STiPodDataStore selectedCalendarIDsForDevice:sn] allObjects];
    EKEventStore *eventStore = [[[NSApp delegate] calendarProvider] eventStore];
    
    NSMutableArray *calendars = [NSMutableArray array];
    for (NSString *calID in calendarIDs) {
        EKCalendar *calendar = [eventStore calendarWithIdentifier:calID];
        if (calendar) {
            [calendars addObject:calendar];
        }
    }
    
    NSArray *files = [[[NSApp delegate] calendarProvider] developCalendarFilesForCalendars:calendars];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSURL *fileURL in files) {
        NSURL *targetURL = [destinationURL URLByAppendingPathComponent:fileURL.lastPathComponent];
        
        // Remove existing file at destination to prevent copyItemAtURL from failing
        if ([fileManager fileExistsAtPath:targetURL.path]) {
            if (![fileManager removeItemAtURL:targetURL error:&error]) {
                abort();
                return NO;
            }
        }
        
        // Copy item to target path
        if (![fileManager copyItemAtURL:fileURL toURL:targetURL error:&error]) {
            abort();
            return NO;
        }
    }
    
    return true;
}

@end
