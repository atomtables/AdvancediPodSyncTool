//
//  STiPodSyncExecutor.h
//  Advanced iPod Sync Tool
//
//  Created by Adithiya Venkatakrishnan on 5/10/2026.
//  Copyright (c) 2026 Adithiya Venkatakrishnan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STiPodSyncExecutor : NSObject
+ (BOOL)syncAllOntoiPod:(NSString*)sn;
@end
