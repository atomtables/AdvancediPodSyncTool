//
//  AppDelegate.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "STiPodWatcher.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) STiPodWatcher* watcher;

@end

