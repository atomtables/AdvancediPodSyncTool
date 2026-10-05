//
//  STStatusBarController.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 3/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface STStatusBarController : NSObject <NSMenuDelegate>

@property (unsafe_unretained) IBOutlet NSWindow *window;

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (unsafe_unretained) IBOutlet NSMenu* menu;


@end
