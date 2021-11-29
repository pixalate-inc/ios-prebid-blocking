//
//  Pixalate.m
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#include <stdlib.h>
#import "PXBlocking.h"
#import "PXLogger.h"
#import "PXBlockingResult.h"
#import "Private/PXBlockingParameters.h"
#import "PXTimer.h"

static NSString *const PXBaseFraudURL      = @"https://dev-api.pixalate.com/api/v2/hosts/rpc/suspect";

NSTimeInterval const PXRetryIntervals[] = { 1, 2, 4, 8, 16 };
int const PXRetryIntervalsSize = (sizeof PXRetryIntervals) / (sizeof PXRetryIntervals[0]);

@interface PXBlocking ()

- (void)performBlockingRequest:(PXBlockingParameters*)parameters handler:(PXBlockStatusHandler)handler;

@end

@implementation PXBlocking

static PXGlobalConfig* config;
static NSCache<PXBlockingParameters*,PXBlockingResult*>* blockingCache;

+(void)initialize {
    blockingCache = [[NSCache<PXBlockingParameters*,PXBlockingResult*> alloc] init];
}

+(PXGlobalConfig*)globalConfig {
    @synchronized (self) {
        return config;
    }
}

+(void)setGlobalConfig:(PXGlobalConfig *)val {
    @synchronized (self) {
        config = val;
        
        if( config != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Set global config: Username: %@ -- Threshold: %f -- CacheAge: %f -- TimeoutInterval: %f", config.apiKey, config.threshold, config.ttl, config.timeoutInterval];
        }
    }
}

+ (void) setLogLevel: (PXLogLevel)level {
    [PXLogger setLogLevel:level];
}

+ (void)requestBlockStatus:(PXBlockStatusHandler)handler {
    if( PXBlocking.globalConfig == nil ) {
        @throw [[NSException alloc]
                initWithName:@"PXInvalidStateException"
                reason:@"You must configure Pixalate.globalConfig before you can request block status."
                userInfo:nil];
    }
    
    __block NSString *deviceId = nil;
    __block NSString *ipv4 = nil;
    __block NSString *ipv6 = nil;
    __block NSString *userAgent = nil;
    
    __block int activityCount = 4;
    
    __block typeof(self) blockSelf = self;
    
    
    void (^completeActivity)(NSString*) = ^(NSString *debugName) {
        [PXLogger logWithFormat:PXLogLevelDebug message:@"Completed activity: %@", debugName];
        activityCount -= 1;
        
        if( activityCount == 0 ) {
            PXBlockingParametersBuilder *builder = [[PXBlockingParametersBuilder alloc] init];
            builder.deviceId = deviceId;
            builder.ipv4 = ipv4;
            builder.ipv6 = ipv6;
            builder.userAgent = userAgent;
            
            PXBlockingParameters *params = [PXBlockingParameters makeWithBuilder:^(PXBlockingParametersBuilder *builder) {
                builder.deviceId = deviceId;
                builder.ipv4 = ipv4;
                builder.ipv6 = ipv6;
                builder.userAgent = userAgent;
            }];
            
            activityCount = -1;
            
            [PXLogger log:PXLogLevelDebug message:@"All activities completed."];
            [blockSelf performBlockingRequest:params handler:handler];
        }
    };
    
    [PXBlocking.globalConfig.strategy getDeviceId:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting device id: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched device id: %@", result];
        }
        
        deviceId = result;
        
        completeActivity(@"Device ID");
    }];
    
    [PXBlocking.globalConfig.strategy getIPv4Address:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting ipv4: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched ipv4: %@", result];
        }
        
        ipv4 = result;
        
        completeActivity(@"IPv4");
    }];
    
    [PXBlocking.globalConfig.strategy getIPv6Address:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting ipv6: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched ipv6: %@", result];
        }
        
        ipv6 = result;
        
        completeActivity(@"IPv6");
    }];
    
    [PXBlocking.globalConfig.strategy getUserAgent:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting user agent: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched user agent: %@", result];
        }
        
        userAgent = result;
        
        completeActivity(@"User Agent");
    }];
}

- (void) performBlockingRequest:(PXBlockingParameters*)parameters
                        handler:(PXBlockStatusHandler)handler {
    
    PXBlockingResult *result = [blockingCache objectForKey:parameters];
    
    if( PXBlocking.globalConfig.ttl > 0 ) {
        if( result != nil ) {
            if( result.isValid ) {
                BOOL res = result.probability > PXBlocking.globalConfig.threshold;
                handler( res, nil );
                return;
            } else {
                [blockingCache removeObjectForKey:parameters];
            }
        }
    }
    
    NSURLComponents *urlBuilder = [[NSURLComponents alloc] initWithString:PXBaseFraudURL];
    
    NSMutableArray<NSURLQueryItem*> *items = [[NSMutableArray<NSURLQueryItem*> alloc] initWithCapacity:5];
    
    if( parameters.deviceId != nil ) {
        [items addObject:[[NSURLQueryItem alloc] initWithName:@"deviceId" value:parameters.deviceId]];
    }
    if( parameters.userAgent != nil ) {
        [items addObject:[[NSURLQueryItem alloc] initWithName:@"userAgent" value:parameters.userAgent]];
    }
    if( parameters.ipv4 != nil ) {
        [items addObject:[[NSURLQueryItem alloc] initWithName:@"ip" value:parameters.ipv4]];
    }
    if( parameters.ipv6 != nil ) {
        [PXLogger log:PXLogLevelInfo message:@"Warning: IPv6 is not yet supported, so the passed IPv6 value will not be used."];
    }
    
    [urlBuilder setQueryItems:items];
    
    NSURL* url = urlBuilder.URL;
    
    [PXLogger logWithFormat:PXLogLevelDebug message:@"Block Status URL: %@", url.absoluteString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = PXBlocking.globalConfig.timeoutInterval;
    [request addValue:PXBlocking.globalConfig.apiKey forHTTPHeaderField:@"X-Api-Key"];
    
    NSURLSessionDataTask *task = [PXBlocking.globalConfig.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error retrieving block status: %@", error];
            handler( NO, error );
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Error retrieving block status: %@", error];
            handler( NO, error );
            return;
        }
        
        NSNumber *status = json[ @"status" ];
        
        if( status != nil ) {
            NSString *desc = NSLocalizedString(json[ @"message" ], nil);
            
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: desc
                                       };
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:[status integerValue] userInfo:userInfo];
            handler( NO, error );
            return;
        }
        
        NSNumber *probability = json[ @"probability" ];
        
        [PXLogger logWithFormat:PXLogLevelDebug message:@"Probability: %@", probability];
        
        BOOL res = [probability doubleValue] > PXBlocking.globalConfig.threshold;
        
        if( PXBlocking.globalConfig.ttl > 0 ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Caching blocking result: IPv4: %@ -- IPv6: %@ -- UserAgent: %@ -- DeviceId: %@ -- Probability: %f", parameters.ipv4, parameters.ipv6, parameters.userAgent, parameters.deviceId, probability ];
            [blockingCache setObject:[PXBlockingResult makeWithProbability:[probability doubleValue]] forKey:[parameters copy]];
        }
        
        handler( res, error );
    }];
    
    [task resume];
}

@end
