//
//  PXDefaultBlockingStrategy.h
//  pixalate-prebid
//
//  Created by Pixalate on 11/17/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#ifndef PXDefaultBlockingStrategy_h
#define PXDefaultBlockingStrategy_h

#import <Foundation/Foundation.h>
#import "PXBlockingStrategyProtocol.h"

@interface PXDefaultBlockingStrategy : NSObject <PXBlockingStrategyProtocol>

@property(nonatomic) double ttl; // -1 uses value passed through config
@property(nonatomic) double timeoutInterval; // -1 uses value passed through config

- (instancetype _Nonnull) init;
- (instancetype _Nonnull) initWithTTL:(double)ttl;
- (instancetype _Nonnull) initWithTTL:(double)ttl timeoutInterval:(double)timeoutInterval;

- (void) getDeviceIdImpl:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getIPv4AddressImpl:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getIPv6AddressImpl:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getUserAgentImpl:(PXBlockingStrategyResultHandler)resultHandler;

@end

#endif /* PXDefaultBlockingStrategy_h */
