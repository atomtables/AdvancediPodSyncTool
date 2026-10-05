//
//  STCalendarEventsProvider.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 4/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "AppDelegate.h"
#import "STCalendarEventsProvider.h"
#import <EventKit/EventKit.h>

@interface STCalendarCurrentEventsProvider ()

@property (copy, nonatomic) NSDate* eventCacheDate;
@property (copy, nonatomic) NSDate* reminderCacheDate;
@property (nonatomic) NSArray* cachedEvents;
@property (nonatomic) NSArray* cachedReminders;

@end

@implementation STCalendarCurrentEventsProvider {
    BOOL inited1;
    BOOL inited2;
    BOOL calendarPermissionGranted;
    BOOL reminderPermissionGranted;
    BOOL waitingForReminderListToPopulate;
}

- (id)init {
    if (![NSClassFromString(@"EKEventStore") class]) {
        [[NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Fatal Error: Attempt to use CurrentEventsProvider on system where EventKit is not supported"
                               userInfo:nil] raise];
    }
    
    
    if (self = [super init]) {
        self.eventStore = [[EKEventStore alloc] init];
    }
    
    SEL modernSelector = NSSelectorFromString(@"requestFullAccessToEventsWithCompletion:");
    if ([self.eventStore respondsToSelector:modernSelector]) {
        // We define the block signature used by modern macOS
        // void (^)(BOOL granted, NSError * _Nullable error)
        void (^completionBlock)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
            calendarPermissionGranted = granted;
            inited1 = true;
        };
        // void (*objc_msgSend_request)(id, SEL, id) = (void *)objc_msgSend;
        objc_msgSend(self.eventStore, modernSelector, completionBlock);
        
    } else if ([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            calendarPermissionGranted = granted;
            inited1 = true;
        }];
    } else {
        [[NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Fatal Error: Attempt to use CurrentEventsProvider on system where EventKit is not fully supported"
                               userInfo:nil] raise];
    }
    
    modernSelector = NSSelectorFromString(@"requestFullAccessToRemindersWithCompletion:");
    if ([self.eventStore respondsToSelector:modernSelector]) {
        // We define the block signature used by modern macOS
        // void (^)(BOOL granted, NSError * _Nullable error)
        void (^completionBlock)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
            reminderPermissionGranted = granted;
            inited2 = true;
        };
        // void (*objc_msgSend_request)(id, SEL, id) = (void *)objc_msgSend;
        objc_msgSend(self.eventStore, modernSelector, completionBlock);
        
    } else if ([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [self.eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
            reminderPermissionGranted = granted;
            inited2 = true;
        }];
    } else {
        [[NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Fatal Error: Attempt to use CurrentEventsProvider on system where EventKit is not fully supported"
                               userInfo:nil] raise];
    }
    
    return self;
}

- (BOOL)calendarAccessProvided {
    while (!(inited1 || inited2)) {
        NSDate *shortBurp = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:shortBurp];
    }
    return calendarPermissionGranted;
}

- (BOOL)reminderAccessProvided {
    while (!(inited1 || inited2)) {
        NSDate *shortBurp = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:shortBurp];
    }
    return reminderPermissionGranted;
}

- (NSArray*)allAccounts {
    return [[self eventStore] sources];
}

- (NSArray*)allCalendars {
    return [[self eventStore] calendarsForEntityType:EKEntityTypeEvent];
}

- (NSArray*)calendarsForAccount:(EKSource*)source {
    return [[source calendarsForEntityType:EKEntityTypeEvent] allObjects];
}

#pragma MARK

- (NSArray*)cachedEvents {
    if (([self.eventCacheDate timeIntervalSinceNow] > 60*5) || !_cachedEvents) {
        NSPredicate* pred = [self.eventStore predicateForEventsWithStartDate:[NSDate date]
                                                                     endDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*365]
                                                                   calendars:nil];
        _cachedEvents = [self.eventStore eventsMatchingPredicate:pred];
        self.eventCacheDate = [NSDate dateWithTimeIntervalSinceNow:0];
    }
    return _cachedEvents;
}
- (NSArray*)cachedReminders {
    if (([self.reminderCacheDate timeIntervalSinceNow] > 60*5) || !_cachedReminders) {
        waitingForReminderListToPopulate = true;
        NSPredicate* pred = [self.eventStore predicateForIncompleteRemindersWithDueDateStarting:nil
                                                                                         ending:nil
                                                                                      calendars:nil];
        
        [self.eventStore fetchRemindersMatchingPredicate:pred completion:^(NSArray* rems) {
            _cachedReminders = rems;
            waitingForReminderListToPopulate = false;
            self.reminderCacheDate = [NSDate dateWithTimeIntervalSinceNow:0];
        }];
    }
    while (waitingForReminderListToPopulate) {
        NSDate *shortBurp = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:shortBurp];
    }
    return _cachedReminders;
}
- (long)totalEventCount {
    return [[self cachedEvents] count];
}
- (long)totalReminderCount {
    return [[self cachedReminders] count];
}
- (NSArray*)allEvents {
    return [self cachedEvents];
}
- (NSArray*)allReminders {
    return [self cachedReminders];
}

// if you thought i was GENUINELY bouta write this function you were wrong mi amigo
- (NSArray *)developCalendarFilesForCalendars:(NSArray *)calendars {
    if (!calendars || calendars.count == 0) return @[];
    
    NSMutableArray *icsFiles = [NSMutableArray array];
    
    // Obtain the EKEventStore instance from your delegate/provider
    EKEventStore *eventStore = [[[NSApp delegate] calendarProvider] eventStore];
    
    // Define sync date range (e.g., 1 year in the past to 2 years in the future)
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    
    [offset setYear:-1];
    NSDate *startDate = [gregorian dateByAddingComponents:offset toDate:[NSDate date] options:0];
    
    [offset setYear:2];
    NSDate *endDate = [gregorian dateByAddingComponents:offset toDate:[NSDate date] options:0];
    
    // iCalendar spec (RFC 5545) date formatters
    NSDateFormatter *utcFormatter = [[NSDateFormatter alloc] init];
    [utcFormatter setDateFormat:@"yyyyMMdd'T'HHmmss'Z'"];
    [utcFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    NSDateFormatter *allDayFormatter = [[NSDateFormatter alloc] init];
    [allDayFormatter setDateFormat:@"yyyyMMdd"];
    
    NSString *nowStamp = [utcFormatter stringFromDate:[NSDate date]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Create a unique subfolder name inside NSTemporaryDirectory()
    NSString *uniqueFolder = [NSString stringWithFormat:@"iPodSync_%@", [[NSUUID UUID] UUIDString]];
    NSURL *tempDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                         URLByAppendingPathComponent:uniqueFolder
                         isDirectory:YES];
    
    NSError* error;
    // Create the temporary folder on disk
    BOOL created = [fileManager createDirectoryAtURL:tempDirURL
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error];
    
    for (EKCalendar *calendar in calendars) {
        // Fetch events matching the date range for this calendar
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate
                                                                     endDate:endDate
                                                                   calendars:@[calendar]];
        NSArray *events = [eventStore eventsMatchingPredicate:predicate];
        
        NSMutableString *icsContent = [NSMutableString string];
        [icsContent appendString:@"BEGIN:VCALENDAR\r\n"];
        [icsContent appendString:@"VERSION:2.0\r\n"];
        [icsContent appendString:@"PRODID:-//Advanced iPod Sync Tool//EN\r\n"];
        [icsContent appendFormat:@"X-WR-CALNAME:%@\r\n", [self escapeICSString:calendar.title]];
        
        for (EKEvent *event in events) {
            [icsContent appendString:@"BEGIN:VEVENT\r\n"];
            [icsContent appendFormat:@"UID:%@\r\n", event.calendarItemIdentifier ?: event.eventIdentifier];
            [icsContent appendFormat:@"DTSTAMP:%@\r\n", nowStamp];
            
            if (event.isAllDay) {
                [icsContent appendFormat:@"DTSTART;VALUE=DATE:%@\r\n", [allDayFormatter stringFromDate:event.startDate]];
                // End date in ICS for all-day events is exclusive, so add 1 day
                NSDate *nextDay = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:event.endDate options:0];
                [icsContent appendFormat:@"DTEND;VALUE=DATE:%@\r\n", [allDayFormatter stringFromDate:nextDay]];
            } else {
                [icsContent appendFormat:@"DTSTART:%@\r\n", [utcFormatter stringFromDate:event.startDate]];
                [icsContent appendFormat:@"DTEND:%@\r\n", [utcFormatter stringFromDate:event.endDate]];
            }
            
            if (event.title.length > 0) {
                [icsContent appendFormat:@"SUMMARY:%@\r\n", [self escapeICSString:event.title]];
            }
            if (event.location.length > 0) {
                [icsContent appendFormat:@"LOCATION:%@\r\n", [self escapeICSString:event.location]];
            }
            if (event.notes.length > 0) {
                [icsContent appendFormat:@"DESCRIPTION:%@\r\n", [self escapeICSString:event.notes]];
            }
            
            [icsContent appendString:@"END:VEVENT\r\n"];
        }
        
        [icsContent appendString:@"END:VCALENDAR\r\n"];
        
        // Sanitize calendar name for local filesystem write
        NSString *safeFileName = [calendar.title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        safeFileName = [safeFileName stringByReplacingOccurrencesOfString:@":" withString:@"_"];
        safeFileName = [safeFileName stringByAppendingPathExtension:@"ics"];

        NSURL *fileURL = [tempDirURL URLByAppendingPathComponent:safeFileName];
        
        BOOL success = [icsContent writeToURL:fileURL
                                  atomically:YES
                                    encoding:NSUTF8StringEncoding
                                       error:&error];
        if (!success) {
            // Clean up created folder if write fails
            [fileManager removeItemAtURL:tempDirURL error:nil];
            return nil;
        }
        
        [icsFiles addObject:fileURL];
    }
    
    return [icsFiles copy];
}

- (NSString *)escapeICSString:(NSString *)string {
    if (!string) return @"";
    NSMutableString *escaped = [string mutableCopy];
    [escaped replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@";" withString:@"\\;" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"," withString:@"\\," options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, escaped.length)];
    return escaped;
}

#pragma MARK
@end

