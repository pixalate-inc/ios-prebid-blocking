//
//  BlockingStrategy.h
//  pixalate-prebid-blocking
//
//  Created by Pixalate on 11/17/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#ifndef PXBlockingStrategyProtocol_h
#define PXBlockingStrategyProtocol_h

typedef void (^PXBlockingStrategyResultHandler)(NSString* _Nullable result, NSError * _Nullable error);

@protocol PXBlockingStrategyProtocol

- (void) getDeviceId:(PXBlockingStrategyResultHandler _Nonnull)resultHandler;
- (void) getIPv4Address:(PXBlockingStrategyResultHandler _Nonnull)resultHandler;
- (void) getIPv6Address:(PXBlockingStrategyResultHandler _Nonnull)resultHandler;
- (void) getUserAgent:(PXBlockingStrategyResultHandler _Nonnull)resultHandler;

@end

#endif /* PXBlockingStrategyProtocol_h */
