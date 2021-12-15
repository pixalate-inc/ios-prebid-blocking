//
//  PXLogger.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXLogger_h
#define PXLogger_h

#import <Foundation/Foundation.h>

#import "PXLogLevel.h"

@interface PXLogger : NSObject

+ (void)setLogLevel:(PXLogLevel)level;
+ (void)logWithFormat:(PXLogLevel)level message:(NSString* _Nullable)message, ...;
+ (void)log:(PXLogLevel)level message:(NSString* _Nullable)message;

@end

#endif /* PXLogger_h */
