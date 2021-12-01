//
//  MPAnalyticsTracker.m
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAnalyticsTracker.h"
#import "MPAdConfiguration.h"
#import "MPCoreInstanceProvider.h"
#import "MPHTTPNetworkSession.h"
#import "MPLogging.h"
#import "MPURLRequest.h"

#import <StoreKit/StoreKit.h>

// For non-module targets, UIKit must be explicitly imported
// since MoPubSDK-Swift.h will not import it.
#if __has_include(<MoPubSDK/MoPubSDK-Swift.h>)
    #import <UIKit/UIKit.h>
    #import <MoPubSDK/MoPubSDK-Swift.h>
#else
    #import <UIKit/UIKit.h>
    #import "MoPubSDK-Swift.h"
#endif

@implementation MPAnalyticsTracker

+ (MPAnalyticsTracker *)sharedTracker
{
    static MPAnalyticsTracker * sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[self alloc] init];
    });
    return sharedTracker;
}

@end

@implementation MPAnalyticsTracker (MPAnalyticsTracker)

- (void)trackImpressionForConfiguration:(MPAdConfiguration *)configuration
{
    // Take the @c impressionTrackingURLs array from @c configuration and use the @c sendTrackingRequestForURLs method
    // to actually send the requests.
    MPLogDebug(@"Tracking impression: %@", configuration.impressionTrackingURLs.firstObject);
    [self sendTrackingRequestForURLs:configuration.impressionTrackingURLs];

    // Track SKAdNetwork startImpression
    [self trackSKAdNetworkStartImpressionForConfiguration:configuration];
}

- (void)trackClickForConfiguration:(MPAdConfiguration *)configuration
{
    MPLogDebug(@"Tracking click: %@", configuration.clickTrackingURLs.firstObject);
    [self sendTrackingRequestForURLs:configuration.clickTrackingURLs];
}

- (void)sendTrackingRequestForURLs:(NSArray<NSURL *> *)URLs
{
    for (NSURL *URL in URLs) {
        MPURLRequest * trackingRequest = [[MPURLRequest alloc] initWithURL:URL];
        if (trackingRequest == nil) {
            continue;
        }
        [MPHTTPNetworkSession startTaskWithHttpRequest:trackingRequest];
    }
}

- (void)trackEndImpressionForConfiguration:(MPAdConfiguration *)configuration {
    if (@available(iOS 14.5, *)) {
        SKAdImpression *storeKitImpression = configuration.skAdNetworkData.impressionData;
        if (storeKitImpression == nil) {
            return;
        }

        [SKAdNetwork endImpression:storeKitImpression completionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                return;
            }
            MPLogError(@"SKAdNetwork endImpression failed with error: %@", error);
        }];
    }
}

- (void)trackSKAdNetworkStartImpressionForConfiguration:(MPAdConfiguration *)configuration {
    if (@available(iOS 14.5, *)) {
        SKAdImpression *storeKitImpression = configuration.skAdNetworkData.impressionData;
        if (storeKitImpression == nil) {
            return;
        }

        [SKAdNetwork startImpression:storeKitImpression completionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                return;
            }
            MPLogError(@"SKAdNetwork startImpression failed with error: %@", error);
        }];
    }
}

@end
