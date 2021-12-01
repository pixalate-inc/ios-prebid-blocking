//
//  PXGlobalConfig.m
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#import "PXGlobalConfig.h"
#import "PXDefaultBlockingStrategy.h"

const int PXDefaultCacheAge = 60 * 60 * 8; // 8 hours in seconds
const double PXDefaultThreshold = 0.75;
const double PXDefaultTimeoutInterval = 2; // in seconds


@implementation PXGlobalConfigBuilder

@synthesize threshold = _threshold;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize ttl = _ttl;
@synthesize urlSession = _urlSession;
@synthesize strategy = _strategy;

-(void) setThreshold:(double)threshold {
    if( threshold < 0.1 || threshold > 1 ) {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"Threshold must be within 0.1 and 1 inclusive (got %f).", threshold] userInfo:nil];
    }

    _threshold = threshold;
}

-(void) setTimeoutInterval:(double)timeoutInterval {
    if( timeoutInterval <= 0 ) {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"Timeout interval must be greater than 0 (got %f).", timeoutInterval] userInfo:nil];
    }

    _timeoutInterval = timeoutInterval;
}

-(void) setTtl:(double)ttl {
    if( ttl < 0 ) ttl = 0;
    _ttl = ttl;
}

-(void) setUrlSession:(NSURLSession *)urlSession {
    if( urlSession == nil ) urlSession = NSURLSession.sharedSession;
    _urlSession = urlSession;
}

-(void) setStrategy:(PXBlockingStrategy*)strategy {
    _strategy = strategy;
}

-(instancetype)init NS_UNAVAILABLE NS_SWIFT_UNAVAILABLE("use initWithApiKey:") {
    return nil;
}

-(instancetype)initWithApiKey:(NSString*)apiKey {
    return [self initWithApiKey:apiKey threshold:PXDefaultThreshold ttl:PXDefaultCacheAge timeoutInterval:PXDefaultTimeoutInterval strategy:nil];
}

-(instancetype)initWithApiKey:(NSString*)apiKey
                     strategy:(PXBlockingStrategy*)strategy {
    return [self initWithApiKey:apiKey threshold:PXDefaultThreshold ttl:PXDefaultCacheAge timeoutInterval:PXDefaultTimeoutInterval strategy:strategy];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold {
    return [self initWithApiKey:apiKey threshold:threshold ttl:PXDefaultCacheAge timeoutInterval:PXDefaultTimeoutInterval strategy:nil];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold
                     strategy:(PXBlockingStrategy*)strategy {
    return [self initWithApiKey:apiKey threshold:threshold ttl:PXDefaultCacheAge timeoutInterval:PXDefaultTimeoutInterval strategy:strategy];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold
                          ttl:(int)ttl {
    return [self initWithApiKey:apiKey threshold:threshold ttl:ttl timeoutInterval:PXDefaultTimeoutInterval strategy:nil];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold
                          ttl:(int)ttl
                     strategy:(PXBlockingStrategy*)strategy {
    return [self initWithApiKey:apiKey threshold:threshold ttl:ttl timeoutInterval:PXDefaultTimeoutInterval strategy:strategy];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold
                          ttl:(int)ttl
              timeoutInterval:(double)timeoutInterval {
    return [self initWithApiKey:apiKey threshold:threshold ttl:ttl timeoutInterval:timeoutInterval strategy:nil];
}
-(instancetype)initWithApiKey:(NSString*)apiKey
                    threshold:(double)threshold
                          ttl:(int)ttl
              timeoutInterval:(double)timeoutInterval
                     strategy:(PXBlockingStrategy*)strategy {
    self.apiKey = apiKey;
    self.threshold = threshold;
    self.ttl = ttl;
    self.timeoutInterval = timeoutInterval;
    self.urlSession = NSURLSession.sharedSession;
    self.strategy = strategy;

    return self;
}
@end

@interface PXGlobalConfig ()

@property(nonatomic,copy) NSString *apiKey;
@property(nonatomic) PXBlockingStrategy *strategy;
@property(nonatomic) double threshold;
@property(nonatomic) double ttl;
@property(nonatomic) double timeoutInterval;
@property(nonatomic) NSURLSession *urlSession;

@end

@implementation PXGlobalConfig

-(instancetype)init NS_SWIFT_UNAVAILABLE("use initWithBuilder:") {
    return self;
}

-(instancetype)initWithBuilder:(PXGlobalConfigBuilder*)builder {
    self.apiKey = builder.apiKey;
    self.threshold = builder.threshold;
    self.ttl = builder.ttl;
    self.timeoutInterval = builder.timeoutInterval;
    self.urlSession = builder.urlSession;
    if( builder.strategy == nil ) {
        PXDefaultBlockingStrategy *defaultStrategy = [[PXDefaultBlockingStrategy alloc] initWithTTL:builder.ttl timeoutInterval:builder.timeoutInterval];
        self.strategy = defaultStrategy;
    } else {
        if( [builder.strategy class] == [PXDefaultBlockingStrategy class] ) {
            PXDefaultBlockingStrategy *strategy = (PXDefaultBlockingStrategy *) builder.strategy;
            if( strategy.ttl == -1 ) {
                strategy.ttl = builder.ttl;
            }
            
            if( strategy.timeoutInterval == -1 ) {
                strategy.timeoutInterval = builder.timeoutInterval;
            }
        }
        self.strategy = builder.strategy;
    }
    
    return self;
}

+(instancetype)makeWithApiKey:(NSString*)apiKey {
    PXGlobalConfigBuilder *builder = [[PXGlobalConfigBuilder alloc] init];
    builder.apiKey = apiKey;
    
    PXGlobalConfig *config = [[PXGlobalConfig alloc] initWithBuilder:builder];
    return config;
}

+(instancetype)makeWithApiKey:(NSString*)apiKey builder:(void (^)(PXGlobalConfigBuilder *builder))updateBlock {
    PXGlobalConfigBuilder *builder = [[PXGlobalConfigBuilder alloc] initWithApiKey:apiKey];
    updateBlock( builder );
    
    PXGlobalConfig *config = [[PXGlobalConfig alloc] initWithBuilder:builder];
    return config;
}

@end
