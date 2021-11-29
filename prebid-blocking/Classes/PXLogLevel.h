//
//  PXLogLevel.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXLogLevel_h
#define PXLogLevel_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXLogLevel) {
    PXLogLevelNone = 0,
    PXLogLevelInfo = 1,
    PXLogLevelDebug = 2
};

#endif /* PXLogLevel_h */
