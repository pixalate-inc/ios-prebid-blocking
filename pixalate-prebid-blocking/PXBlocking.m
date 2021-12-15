//
//  PXBlocking.m
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#import <stdlib.h>
#import "PXBlocking.h"
#import "PXLogger.h"
#import "PXBlockingResult.h"
#import "Private/PXBlockingParameters.h"
#import "PXErrorCodes.h"

static NSString *const PXBaseFraudURL = @"https://dev-api.pixalate.com/api/v2/hosts/rpc/suspect";

@interface PXBlocking ()

+ (void)performBlockingRequest:(PXBlockingParameters*)parameters
              timeoutRemaining:(double)timeoutRemaining
                       handler:(PXBlockStatusHandler)handler;

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
    [self requestBlockStatusWithBlockingMode:PXBlockingModeDefault handler:handler];
}

+ (void)requestBlockStatusWithBlockingMode:(PXBlockingMode)mode handler:(PXBlockStatusHandler)handler {
    if( PXBlocking.globalConfig == nil ) {
        @throw [[NSException alloc]
                initWithName:@"PXInvalidStateException"
                reason:@"You must configure Pixalate.globalConfig before you can request block status."
                userInfo:nil];
    }
    
    __block PXBlockingParametersBuilder *builder = [[PXBlockingParametersBuilder alloc] init];
    
    __block double startTime = [[NSDate date] timeIntervalSince1970];
    __block int activityCount = 4;
    
    __weak NSTimer *abortTimer = nil;
    
    [PXLogger logWithFormat:PXLogLevelDebug
                    message:@"Starting block request: Timeout = %f --- TTL = %f",
     
         PXBlocking.globalConfig.timeoutInterval,
         PXBlocking.globalConfig.ttl
    ];
    
    if( PXBlocking.globalConfig.timeoutInterval > 0 ) {
        abortTimer = [NSTimer scheduledTimerWithTimeInterval:PXBlocking.globalConfig.timeoutInterval repeats:false block:^(NSTimer *timer) {
            
            activityCount = -1;
            
            NSDictionary *userInfo = @{
                NSLocalizedFailureReasonErrorKey: @"Timeout interval reached while attempting to execute the blocking strategy.",
                NSLocalizedRecoverySuggestionErrorKey: @"You may increase the timeout interval.",
                NSLocalizedDescriptionKey: @"Blocking Request Aborted"
            };
            
            handler(false, [[NSError alloc] initWithDomain:@"com.pixalate.prebid-block" code:PXBlockingRequestAbortedErrorCode userInfo:userInfo]);
        }];
    }
    
    void (^completeActivity)(void) = ^() {
        activityCount -= 1;
        
        if( activityCount == 0 ) {
            activityCount = -1;
            
            PXBlockingParameters *params = [[PXBlockingParameters alloc] initWithBuilder:builder];
            
            [PXLogger log:PXLogLevelDebug message:@"All activities completed."];
            
            if( abortTimer != nil ) {
                [abortTimer invalidate];
            }
            
            double now = [[NSDate date] timeIntervalSince1970];
            double spent = now - startTime;
            double remaining = PXBlocking.globalConfig.timeoutInterval - spent;
            
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Remaining timeout for request itself:%f", remaining];
            
            if( mode == PXBlockingModeDefault ) {
                [PXBlocking performBlockingRequest:params timeoutRemaining:remaining handler:handler];
            } else if( mode == PXBlockingModeAlwaysBlock ) {
                handler(true,nil);
            } else if( mode == PXBlockingModeNeverBlock ) {
                handler(false,nil);
            }
        }
    };
    
    [PXBlocking.globalConfig.strategy getDeviceId:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting device id, ignoring value: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched device id: %@", result];
            builder.deviceId = result;
        }
        
        completeActivity();
    }];
    
    [PXBlocking.globalConfig.strategy getIPv4Address:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting ipv4, ignoring value: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched ipv4: %@", result];
            builder.ipv4 = result;
        }
        
        completeActivity();
    }];
    
    [PXBlocking.globalConfig.strategy getIPv6Address:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting ipv6, ignoring value: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched ipv6: %@", result];
            builder.ipv6 = result;
        }
        
        completeActivity();
    }];
    
    [PXBlocking.globalConfig.strategy getUserAgent:^(NSString *result, NSError *error) {
        if( error != nil ) {
            [PXLogger logWithFormat:PXLogLevelInfo message:@"Error occurred getting user agent, ignoring value: %@", error];
        } else {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Successfully fetched user agent: %@", result];
            builder.userAgent = result;
        }
        
        completeActivity();
    }];
}

+ (void) performBlockingRequest:(PXBlockingParameters*)parameters
               timeoutRemaining:(double)timeoutRemaining
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
    request.timeoutInterval = timeoutRemaining;
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
        
        NSNumber *probabilityValue = json[ @"probability" ];
        double rawProbability = [probabilityValue doubleValue];
        
        [PXLogger logWithFormat:PXLogLevelDebug message:@"Probability: %f", rawProbability];
        
        BOOL res = rawProbability > PXBlocking.globalConfig.threshold;
        
        if( PXBlocking.globalConfig.ttl > 0 ) {
            [PXLogger logWithFormat:PXLogLevelDebug message:@"Caching blocking result: IPv4: %@ -- IPv6: %@ -- UserAgent: %@ -- DeviceId: %@ -- Probability: %f", parameters.ipv4, parameters.ipv6, parameters.userAgent, parameters.deviceId, rawProbability];
            [blockingCache setObject:[PXBlockingResult makeWithProbability:rawProbability] forKey:[parameters copy]];
        }
        
        handler( res, error );
    }];
    
    [task resume];
}

@end
