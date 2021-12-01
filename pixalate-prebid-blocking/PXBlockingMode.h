//
//  PXBlockingMode.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXBlockingMode_h
#define PXBlockingMode_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXBlockingMode) {
    PXBlockingModeDefault = 0,
    PXBlockingModeAlwaysBlock = 1,
    PXBlockingModeNeverBlock = 2
};

#endif /* PXBlockingMode_h */
