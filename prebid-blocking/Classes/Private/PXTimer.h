//
//  PXTimer.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXTimer_h
#define PXTimer_h

#import <Foundation/Foundation.h>

typedef void (^PXTimerBlock)(void);

@interface PXTimer : NSObject

@property(nonatomic,copy) PXTimerBlock block;

+(instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(PXTimerBlock)block;
-(void)timerHandler:(NSTimer*)timer;
-(instancetype)initWithBlock:(PXTimerBlock)block;

@end

#endif /* PXTimer_h */
