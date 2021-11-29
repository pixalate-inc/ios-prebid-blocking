//
//  BlockingStrategy.h
//  pixalate-prebid
//
//  Created by Pixalate on 11/17/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#ifndef PXBlockingStrategyProtocol_h
#define PXBlockingStrategyProtocol_h

#define PXBlockingStrategyResultHandler void (^ _Nonnull)(NSString* _Nullable result, NSError * _Nullable error)

@protocol PXBlockingStrategyProtocol

- (void) getDeviceId:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getIPv6Address:(PXBlockingStrategyResultHandler)resultHandler;
- (void) getUserAgent:(PXBlockingStrategyResultHandler)resultHandler;

@end

#endif /* PXBlockingStrategyProtocol_h */
