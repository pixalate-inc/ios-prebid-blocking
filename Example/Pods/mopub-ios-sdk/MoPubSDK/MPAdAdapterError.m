//
//  MPAdAdapterError.m
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAdAdapterError.h"

// TODO: `MPAdAdapterErrorDomain` is going to replace the deprecated `MoPubRewardedAdsSDKDomain`.
// To be backward compatible, the value of `MPAdAdapterErrorDomain` is still "MoPubRewardedAdsSDKDomain".
// Upon removing `MoPubRewardedAdsSDKDomain`, change the value to "MPAdAdapterErrorDomain".
NSString * const MPAdAdapterErrorDomain = @"MoPubRewardedAdsSDKDomain";

@implementation NSError (MPAdAdapterError)

+ (NSError *)errorWithAdAdapterErrorCode:(MPAdAdapterErrorCode)code {
    NSString *errorDescription;
    switch (code) {
        case MPAdAdapterErrorCodeUnknown:
            errorDescription = @"Error unknown";
            break;
        case MPAdAdapterErrorCodeNoAdsAvailable:
            errorDescription = @"No ads available";
            break;
        case MPAdAdapterErrorCodeInvalidAdapter:
            errorDescription = @"Invalid adapter";
            break;
        case MPAdAdapterErrorCodeNoAdReady:
            errorDescription = @"No ad ready";
            break;
        case MPAdAdapterErrorCodeInvalidAdUnitID:
            errorDescription = @"Invalid ad unit ID";
            break;
        case MPAdAdapterErrorCodeInvalidReward:
            errorDescription = @"Invalid reward";
            break;
        case MPAdAdapterErrorCodeNoRewardSelected:
            errorDescription = @"No reward selected";
            break;
        default:
            errorDescription = @"";
            break;
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithAdAdapterErrorCode:code userInfo:userInfo];
}

+ (NSError *)errorWithAdAdapterErrorCode:(MPAdAdapterErrorCode)code userInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:MPAdAdapterErrorDomain code:code userInfo:userInfo];
}

@end
