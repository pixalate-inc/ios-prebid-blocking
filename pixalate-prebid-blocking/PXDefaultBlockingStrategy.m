//
//  PXDefaultBlockingStrategy.m
//  pixalate-prebid-blocking
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

NSString *const PXBaseIPv4URL = @"https://get-ipv4.adrta.com/ipv4";

@interface PXDefaultBlockingStrategy ()

@property(nonatomic) double cachedDeviceIdExpiry;
@property(nonatomic) NSString *cachedDeviceId;

@property(nonatomic) double cachedIPv4Expiry;
@property(nonatomic) NSString *cachedIPv4;

@property(nonatomic) double cachedIPv6Expiry;
@property(nonatomic) NSString *cachedIPv6;

@property(nonatomic) double cachedUserAgentExpiry;
@property(nonatomic) NSString *cachedUserAgent;

@end

@implementation PXDefaultBlockingStrategy

- (instancetype) init {
    self.ttl = -1;
    self.timeoutInterval = -1;
    return self;
}

- (instancetype) initWithTTL:(double)ttl {
    self.ttl = ttl;
    self.timeoutInterval = -1;
    return self;
}

- (instancetype) initWithTTL:(double)ttl timeoutInterval:(double)timeout {
    self.ttl = ttl;
    self.timeoutInterval = timeout;
    
    return self;
}

- (void) getDeviceId:(PXBlockingStrategyResultHandler)resultHandler {
    if( self.ttl > 0 &&
        self.cachedDeviceId != nil &&
        self.cachedDeviceIdExpiry > [[NSDate date] timeIntervalSince1970] ) {
        
        resultHandler( self.cachedDeviceId, nil );
        return;
    }
    
    PXDefaultBlockingStrategy * __weak weakSelf = self;
    [self getDeviceIdImpl:^(NSString *result, NSError *error) {
        if( result != nil && weakSelf.ttl > 0 ) {
            weakSelf.cachedDeviceId = result;
            weakSelf.cachedDeviceIdExpiry = [[NSDate date] timeIntervalSince1970] + weakSelf.ttl;
        }
        
        resultHandler( result, error );
    }];
}

- (void) getDeviceIdImpl:(PXBlockingStrategyResultHandler)resultHandler {
    UIDevice *device = [UIDevice currentDevice];
    resultHandler([[device identifierForVendor] UUIDString],nil);
}

- (void) getIPv4Address:(PXBlockingStrategyResultHandler)resultHandler {
    if( self.ttl > 0 &&
        self.cachedIPv4 != nil &&
        self.cachedIPv4Expiry > [[NSDate date] timeIntervalSince1970] ) {
        
        resultHandler( self.cachedDeviceId, nil );
        return;
    }
    
    PXDefaultBlockingStrategy * __weak weakSelf = self;
    [self getIPv4AddressImpl:^(NSString *result, NSError *error) {
        if( result != nil && weakSelf.ttl > 0 ) {
            weakSelf.cachedIPv4 = result;
            weakSelf.cachedIPv4Expiry = [[NSDate date] timeIntervalSince1970] + weakSelf.ttl;
        }
        
        resultHandler( result, error );
    }];
}

- (void) getIPv4AddressImpl:(PXBlockingStrategyResultHandler)resultHandler {
    NSURL *url = [NSURL URLWithString:PXBaseIPv4URL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = self.timeoutInterval;
    
    NSURLSessionDataTask *task = [PXBlocking.globalConfig.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error retrieving IPv4 address: %@", error];
            resultHandler(nil, error);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error parsing IPv4 response: %@", error];
            resultHandler(nil, error);
            return;
        }
        
        NSString *ipv4 = NSLocalizedString(json[ @"ip" ], nil);
        
        resultHandler(ipv4, nil);
    }];
    
    [task resume];
}

- (void)getIPv6Address:(PXBlockingStrategyResultHandler)resultHandler {
    if( self.ttl > 0 &&
        self.cachedIPv6 != nil &&
        self.cachedIPv6Expiry > [[NSDate date] timeIntervalSince1970] ) {
        
        resultHandler( self.cachedDeviceId, nil );
        return;
    }
    
    PXDefaultBlockingStrategy * __weak weakSelf = self;
    [self getIPv6AddressImpl:^(NSString *result, NSError *error) {
        if( result != nil && weakSelf.ttl > 0 ) {
            weakSelf.cachedIPv6 = result;
            weakSelf.cachedIPv6Expiry = [[NSDate date] timeIntervalSince1970] + weakSelf.ttl;
        }
        
        resultHandler( result, error );
    }];
}

- (void) getIPv6AddressImpl:(PXBlockingStrategyResultHandler)resultHandler {
    resultHandler(nil,nil);
}

- (void) getUserAgent:(PXBlockingStrategyResultHandler)resultHandler {
    if( self.ttl > 0 &&
        self.cachedUserAgent != nil &&
        self.cachedUserAgentExpiry > [[NSDate date] timeIntervalSince1970] ) {
        
        resultHandler( self.cachedDeviceId, nil );
        return;
    }
    
    PXDefaultBlockingStrategy * __weak weakSelf = self;
    [self getUserAgentImpl:^(NSString *result, NSError *error) {
        if( result != nil && weakSelf.ttl > 0 ) {
            weakSelf.cachedUserAgent = result;
            weakSelf.cachedUserAgentExpiry = [[NSDate date] timeIntervalSince1970] + weakSelf.ttl;
        }
        
        resultHandler( result, error );
    }];
}

- (void) getUserAgentImpl:(PXBlockingStrategyResultHandler)resultHandler {
    resultHandler(nil,nil);
}


@end
