//
//  PXDefaultBlockingStrategy.m
//  pixalate-prebid
//
//  Created by Pixalate on 11/17/21.
//  Copyright © 2021 Pixalate. All rights reserved.
//

#import "PXBlockingStrategyProtocol.h"
#import "PXDefaultBlockingStrategy.h"

#import "PXBlocking.h"
#import "Private/PXLogger.h"
#import "PXGlobalConfig.h"
#import <Foundation/Foundation.h>

NSString *const PXBaseIPv4URL = @"https://get-ipv4.adrta.com";

@implementation PXDefaultBlockingStrategy

- (void) getDeviceId:(PXBlockingStrategyResultHandler)resultHandler {
    UIDevice *device = [UIDevice currentDevice];
    resultHandler([[device identifierForVendor] UUIDString],nil);
}

- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler {
    NSURL *url = [NSURL URLWithString:PXBaseIPv4URL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    [PXBlocking.globalConfig.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error retrieving IPv4 address: %@", error];
            resultHandler(nil, error);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error retrieving block status: %@", error];
            resultHandler(nil, error);
            return;
        }
        
        NSString *ipv4 = NSLocalizedString(json[ @"ip" ], nil);
        
        resultHandler(ipv4, nil);
    }];
}

- (void)getIPv6Address:(PXBlockingStrategyResultHandler)resultHandler {
    resultHandler(nil, nil);
}

- (void) getUserAgent:(PXBlockingStrategyResultHandler)resultHandler {
    resultHandler(nil,nil);
}


@end
