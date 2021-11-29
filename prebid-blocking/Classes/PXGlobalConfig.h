//
//  PXGlobalConfig.h
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#ifndef PXGlobalConfig_h
#define PXGlobalConfig_h

#import <Foundation/Foundation.h>

#import "PXBlockingStrategyProtocol.h"

#define PXBlockingStrategy NSObject<PXBlockingStrategyProtocol>

@interface PXGlobalConfigBuilder : NSObject

@property(nonatomic,copy) NSString * _Nonnull apiKey;
@property(nonatomic) NSObject<PXBlockingStrategyProtocol> * _Nullable strategy;
@property(nonatomic) double threshold;
@property(nonatomic) double ttl;
@property(nonatomic) double timeoutInterval;
@property(nonatomic) NSURLSession* _Nonnull urlSession;

- (instancetype _Nonnull)init NS_SWIFT_UNAVAILABLE("use initWithApiKey:");
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold
                              strategy:(PXBlockingStrategy * _Nullable)strategy;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold
                                   ttl:(int)ttl;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold
                                   ttl:(int)ttl
                              strategy:(PXBlockingStrategy * _Nullable)strategy;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold
                                   ttl:(int)ttl
                       timeoutInterval:(double)timeoutInterval;
- (instancetype _Nonnull)initWithApiKey:(NSString* _Nonnull)apiKey
                             threshold:(double)threshold
                                   ttl:(int)ttl
                       timeoutInterval:(double)timeoutInterval
                              strategy:(PXBlockingStrategy * _Nullable)strategy;

@end

@interface PXGlobalConfig : NSObject

@property(nonatomic,copy,readonly) NSString * _Nonnull apiKey;
@property(nonatomic,copy,readonly) PXBlockingStrategy * _Nonnull strategy;
@property(nonatomic,readonly) double threshold;
@property(nonatomic,readonly) double ttl;
@property(nonatomic,readonly) double timeoutInterval;
@property(nonatomic,readonly) NSURLSession* _Nonnull urlSession;

- (instancetype _Nonnull) init NS_SWIFT_UNAVAILABLE("use initWithBuilder:");
- (instancetype _Nonnull) initWithBuilder:(PXGlobalConfigBuilder * _Nonnull) builder;

+ (instancetype _Nonnull) makeWithApiKey:(NSString* _Nonnull)apiKey NS_SWIFT_NAME(make(apiKey:));
+ (instancetype _Nonnull) makeWithApiKey:(NSString* _Nonnull)apiKey builder:(void (^ _Nonnull)(PXGlobalConfigBuilder* _Nonnull))updateBlock NS_SWIFT_NAME(make(apiKey:builder:));

@end

#endif /* PXGlobalConfig_h */
