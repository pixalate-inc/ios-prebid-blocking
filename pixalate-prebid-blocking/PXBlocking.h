//
//  PXBlocking.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXBlocking_h
#define PXBlocking_h

#import <Foundation/Foundation.h>

#import "PXGlobalConfig.h"
#import "PXLogLevel.h"
#import "PXBlockingMode.h"
#import "PXBlockingStrategyProtocol.h"
#import "PXDefaultBlockingStrategy.h"

typedef void (^PXBlockStatusHandler)(BOOL block, NSError * _Nullable error);

@interface PXBlocking : NSObject

+ (PXGlobalConfig* _Nullable)globalConfig;

+ (void)setGlobalConfig:(PXGlobalConfig* _Nonnull)config;
+ (void)setLogLevel:(PXLogLevel)level;

+ (void)requestBlockStatusWithBlockingMode:(PXBlockingMode)mode handler:(PXBlockStatusHandler _Nonnull)handler;
+ (void)requestBlockStatus:(PXBlockStatusHandler _Nonnull)handler;

@end

#endif /* PXBlocking_h */
