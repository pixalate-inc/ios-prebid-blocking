//
//  MPAdContainerView+Private.h
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>
#import "MPAdContainerView.h"
#import "MPAdViewOverlay.h"
#import "MPVASTCompanionAdView.h"
#import "MPVideoConfig.h"
#import "MPVideoPlayerView.h"
#import "MPViewableVisualEffectView.h"
#import "MPWebView.h"

@class MPImageCreativeView;
@class MPStopwatch;

typedef NS_ENUM(NSUInteger, MPAdExperienceState) {
    /*
     The ad experience has not started.
     */
    MPAdExperienceStateNotStarted = 0,

    /*
     The ad experience has started.
     */
    MPAdExperienceStateStarted,

    /*
     The ad experience has finished and the close button has been shown.
     */
    MPAdExperienceStateFinished
};

NS_ASSUME_NONNULL_BEGIN

@interface MPAdContainerView ()
@property (nonatomic, assign) BOOL isVideoFinished; // default to NO

@property (nonatomic, strong) MPAdViewOverlay *overlay;
@property (nonatomic, strong) MPWebView *webContentView;
@property (nonatomic, strong) MPImageCreativeView *imageCreativeView;

#pragma mark - Video
/**
 Video configuration containing the video asset to render and video player settings.
 */
@property (nonatomic, strong) MPVideoConfig *videoConfig;

/**
 View responsible for rendering the VAST video player. This is optional since the creative may not
 have a video to render.
 */
@property (nonatomic, strong, nullable) MPVideoPlayerView *videoPlayerView;

/**
 Optional comapnion ad to render.
 */
@property (nonatomic, strong, nullable) MPVASTCompanionAdView *companionAdView;

/**
 Blur effect that is applied to the last frame of the video when there is no companion ad to show at the end
 of the video.
 @note: This is a friendly obstruction and conforms to @c MPViewabilityObstruction
 */
@property (nonatomic, strong) MPViewableVisualEffectView *blurEffectView;

#pragma mark - Creative Experiences

/**
 The current state of the ad experience.
 */
@property (nonatomic, assign) MPAdExperienceState adExperienceState;

/**
 The index of the currently ad in the overall ad experience.
 Note: Index is used instead of an explicit main ad/end card flag in order to better support potential
 future sequences of ads where there are possibly more than just two ads.
 */
@property (nonatomic, assign) NSUInteger adIndex;

/**
 The amount of time the countdown timer will be shown for the ad at the current ad index.
 */
@property (nonatomic, assign, readonly) NSTimeInterval countdownTimeForCurrentAdIndex;

/**
 A stopwatch to keep track of the total time the user has spent in the ad experience.
 */
@property (nonatomic, strong) MPStopwatch *elapsedAdTimeStopwatch;



@end

NS_ASSUME_NONNULL_END
