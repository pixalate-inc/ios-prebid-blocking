//
//  PXLogger.m
//  pixalate-prebid-blocking
//
//  Created by Pixalate on 11/23/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PXLogger.h"

@implementation PXLogger

static PXLogLevel logLevel;

+ (void)setLogLevel:(PXLogLevel)level {
    logLevel = level;
}

+ (void)logWithFormat:(PXLogLevel)level message:(NSString* _Nullable)message, ... {
    if( level > 0 && level <= logLevel ) {
        va_list args;
        va_start( args, message );
        
        NSString* str = [[NSString alloc] initWithFormat:message arguments:args];
        NSLog( @"PXBlocking: %@", str );
        
        va_end( args );
    }
}

+ (void)log:(PXLogLevel)level message:(NSString* _Nullable)message {
    if( level > 0 && level <= logLevel ) {
        NSLog(@"PXBlocking: %@", message);
    }
}

@end
