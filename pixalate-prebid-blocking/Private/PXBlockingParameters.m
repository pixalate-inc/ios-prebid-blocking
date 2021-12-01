//
//  PXBlockingParameters.m
//  pixalate-prebid-blocking
//
//  Copyright © 2021 Pixalate, Inc.
//  Licensed under the GNU LGPL 3.0.
//

#import "PXBlockingParameters.h"

#define IsEqual(x,y) (x != nil ? [x isEqualToString:y] : y == nil )

@implementation PXBlockingParametersBuilder

@end

@interface PXBlockingParameters ()

@property(nonatomic,copy) NSString* _Nullable deviceId;
@property(nonatomic,copy) NSString* _Nullable userAgent;
@property(nonatomic,copy) NSString* _Nullable ipv4;
@property(nonatomic,copy) NSString* _Nullable ipv6;

@end

@implementation PXBlockingParameters

- (instancetype _Nonnull) init NS_SWIFT_UNAVAILABLE("use initWithBuilder:") {
    return self;
}

- (instancetype) initWithBuilder:(PXBlockingParametersBuilder*) builder {
    self.deviceId = builder.deviceId;
    self.userAgent = builder.userAgent;
    self.ipv4 = builder.ipv4;
    self.ipv6 = builder.ipv6;
    
    return self;
}

+ (instancetype) makeWithBuilder:(void (^)(PXBlockingParametersBuilder*))updateBlock {
    PXBlockingParametersBuilder* builder = [[PXBlockingParametersBuilder alloc] init];
    updateBlock( builder );
    return [[PXBlockingParameters alloc] initWithBuilder:builder];
}

- (id)copyWithZone:(NSZone *)zone {
    PXBlockingParameters *copy = [[PXBlockingParameters alloc] init];
    copy.deviceId = self.deviceId;
    copy.userAgent = self.userAgent;
    copy.ipv4 = self.ipv4;
    copy.ipv6 = self.ipv6;
    
    return copy;
}

- (BOOL)isEqual:(id)object {
    if( self == object ) return YES;
    if( ![object isKindOfClass:[PXBlockingParameters class] ] ) return NO;
    
    PXBlockingParameters *other = (PXBlockingParameters*)object;
    
    if( !IsEqual( self.deviceId, other.deviceId ) ) return NO;
    if( !IsEqual( self.ipv4, other.ipv4 ) ) return NO;
    if( !IsEqual( self.ipv6, other.ipv6 ) ) return NO;
    if( !IsEqual( self.userAgent, other.userAgent ) ) return NO;
    
    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    if( self.deviceId != nil ) result = prime * result + [self.deviceId hash];
    else result = prime * result;
    if( self.userAgent != nil ) result = prime * result + [self.userAgent hash];
    else result = prime * result;
    if( self.ipv4 != nil ) result = prime * result + [self.ipv4 hash];
    else result = prime * result;
    if( self.ipv6 != nil ) result = prime * result + [self.ipv6 hash];
    else result = prime * result;
    
    return result;
}

@end
