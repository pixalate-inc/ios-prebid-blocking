//
//  PXTimer.m
//  pixalate-prebid-blocking
//
//  Created by Pixalate on 11/23/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PXTimer.h"

@implementation PXTimer

- (instancetype)initWithBlock:(PXTimerBlock)block {
    self.block = block;
    return self;
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(PXTimerBlock)block {
    PXTimer* timer = [[PXTimer alloc] initWithBlock:block];
    [NSTimer scheduledTimerWithTimeInterval:interval target:timer selector:@selector(timerHandler:) userInfo:nil repeats:false];
    
    return timer;
}

- (void)timerHandler:(NSTimer *)timer {
    self.block();
}

@end
