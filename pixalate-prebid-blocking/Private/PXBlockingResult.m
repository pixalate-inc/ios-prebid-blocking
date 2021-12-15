//
//  PXBlockingResult.m
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PXBlocking.h"
#import "PXBlockingResult.h"

@implementation PXBlockingResult

+(_Nonnull instancetype)makeWithError:(NSError * _Nonnull)err {
    PXBlockingResult *res = [[PXBlockingResult alloc] init];
    res.error = err;
    res.time = [[NSDate date] timeIntervalSince1970] + PXBlocking.globalConfig.ttl;
    res.probability = 0;
    
    return res;
}

+(_Nonnull instancetype)makeWithProbability:(double)probability {
    PXBlockingResult *res = [[PXBlockingResult alloc] init];
    res.error = nil;
    res.probability = probability;
    res.time = [[NSDate date] timeIntervalSince1970] + PXBlocking.globalConfig.ttl;
    
    return res;
}

-(BOOL)isValid {
    return self.time > [[NSDate date] timeIntervalSince1970];
}

@end
