//
//  STCalendarEventsProvider.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 4/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

#pragma -- MARK
@interface STCalendarCurrentEventsProvider: NSObject

@property (strong, nonatomic) EKEventStore* eventStore;

// User gave consent for us to peep calendar
- (BOOL)calendarAccessProvided;
- (BOOL)reminderAccessProvided;
// List of events in user calendar;
- (long)totalEventCount;
- (long)totalReminderCount;

- (NSArray*)allAccounts;
- (NSArray*)allCalendars;
- (NSArray*)calendarsForAccount:(EKSource*)source;

- (NSArray*)allEvents;
- (NSArray*)allReminders;

- (NSArray*)listOfAllEventsForAccount:(id)account;
- (NSArray*)listOfAllEventsForCalendar:(id)calendar;

// NSArray will be a list of ICS that can be copied over to the iPod
// param is NSArray<EKCalendar*>*
- (NSArray*)developCalendarFilesForCalendars:(NSArray*)calendars;

@end