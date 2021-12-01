//
//  PXBlockingResult.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  GNU Lesser GPL 3.0
//

#ifndef PXBlockingResult_h
#define PXBlockingResult_h

#import <Foundation/Foundation.h>

@interface PXBlockingResult : NSObject

@property(nonatomic,copy) NSError* _Nullable error;
@property(nonatomic) double probability;
@property(nonatomic) double time;

+(instancetype _Nonnull)makeWithError:(NSError* _Nonnull)err;
+(instancetype _Nonnull)makeWithProbability:(double)probability;

-(BOOL)isValid;

@end

#endif /* PXBlockingResult_h */
