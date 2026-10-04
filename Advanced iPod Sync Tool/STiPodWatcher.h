//
//  STiPodWatcher.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STiPodWatcher : NSObject

@property (strong, nonatomic) id connectedObserver;
@property (strong, nonatomic) id disconnectedObserver;
@property (strong, nonatomic) NSMutableDictionary* connectedDevices;

@end
