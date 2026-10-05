//
//  STiPodDataStore.m
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 5/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import "STiPodDataStore.h"

@implementation STiPodDataStore

+ (NSMutableSet*)selectedCalendarIDsForDevice:(NSString *)serialNumber {
    if (!serialNumber) return [NSMutableSet set];
    NSString *key = [NSString stringWithFormat:@"SelectedCalendars_%@", serialNumber];
    NSArray *saved = [[NSUserDefaults standardUserDefaults] stringArrayForKey:key];
    return saved ? [NSMutableSet setWithArray:saved] : [NSMutableSet set];
}

+ (void)setSelectedCalendarIDs:(NSSet*)calendarIDs forDevice:(NSString *)serialNumber {
    if (!serialNumber) return;
    NSString *key = [NSString stringWithFormat:@"SelectedCalendars_%@", serialNumber];
    [[NSUserDefaults standardUserDefaults] setObject:[calendarIDs allObjects] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
