//
//  Pixalate.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXBlocking_h
#define PXBlocking_h

#import <Foundation/Foundation.h>

#import "PXBlockingParameters.h"
#import "PXGlobalConfig.h"
#import "PXLogLevel.h"

#define PXBlockStatusHandler void (^ _Nonnull)(BOOL block, NSError * _Nullable error)

@interface PXBlocking : NSObject

+ (PXGlobalConfig* _Nullable)globalConfig;

+ (void)setGlobalConfig:(PXGlobalConfig* _Nonnull)config;
+ (void)setLogLevel:(PXLogLevel)level;

+ (void)requestBlockStatus:(PXBlockStatusHandler)handler;

@end

#endif /* PXBlocking_h */
