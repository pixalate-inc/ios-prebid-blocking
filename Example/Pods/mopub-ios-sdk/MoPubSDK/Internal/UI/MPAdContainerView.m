//
//  MPAdContainerView.m
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAdContainerView.h"
#import "MPAdContainerView+Private.h"
#import "MPAdViewOverlay.h"
#import "MPLogging.h"
#import "MPVideoPlayerView.h"
#import "MPViewableVisualEffectView.h"
#import "UIView+MPAdditions.h"

// For non-module targets, UIKit must be explicitly imported
// since MoPubSDK-Swift.h will not import it.
#if __has_include(<MoPubSDK/MoPubSDK-Swift.h>)
    #import <UIKit/UIKit.h>
    #import <MoPubSDK/MoPubSDK-Swift.h>
#else
    #import <UIKit/UIKit.h>
    #import "MoPubSDK-Swift.h"
#endif

static const NSTimeInterval kAnimationTimeInterval = 0.5;

#pragma mark -

@interface MPAdContainerView (MPAdViewOverlayDelegate) <MPAdViewOverlayDelegate>
@end

@interface MPAdContainerView (MPVideoPlayerViewDelegate) <MPVideoPlayerViewDelegate>
@end

@interface MPAdContainerView (MPVASTCompanionAdViewDelegate) <MPVASTCompanionAdViewDelegate>
@end

#pragma mark -

@implementation MPAdContainerView

- (instancetype)initWithFrame:(CGRect)frame webContentView:(MPWebView *)webContentView {
    if (self = [self initWithFrame:frame]) {
        _webContentView = webContentView;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;

        [self sharedInitializationStepsWithContentView:webContentView];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame imageCreativeView:(MPImageCreativeView *)imageCreativeView {
    if (self = [self initWithFrame:frame]) {
        _imageCreativeView = imageCreativeView;
        self.opaque = NO;
        self.clipsToBounds = YES;

        [self sharedInitializationStepsWithContentView:imageCreativeView];
        // Set the background color to black to make the presentation animation smooth.
        self.backgroundColor = [UIColor blackColor];
    }

    return self;
}

- (void)dealloc {
    // Stop the stopwatch once the ad is dismissed.
    [self.elapsedAdTimeStopwatch stop];
}

- (void)sharedInitializationStepsWithContentView:(UIView *)contentView {
    self.accessibilityIdentifier = @"com.mopub.adcontainer";

    // It's possible for @c contentView to be @c nil. Don't try to set constraints on a @c nil
    // @c contentView.
    if (contentView != nil) {
        contentView.frame = self.bounds;
        [self addSubview:contentView];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [contentView.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor],
            [contentView.mp_safeLeadingAnchor constraintEqualToAnchor:self.mp_safeLeadingAnchor],
            [contentView.mp_safeBottomAnchor constraintEqualToAnchor:self.mp_safeBottomAnchor],
            [contentView.mp_safeTrailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor]
        ]];
    }

    MPAdViewOverlay *overlay = [[MPAdViewOverlay alloc] initWithFrame:CGRectZero];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    // Set the delegate on the overlay view because we must receive close button events.
    overlay.delegate = self;
    self.overlay = overlay;
    // add after the content view so that the overlay is on top
    [self addSubview:overlay];

    [NSLayoutConstraint activateConstraints:@[
        [self.overlay.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor],
        [self.overlay.mp_safeLeadingAnchor constraintEqualToAnchor:self.mp_safeLeadingAnchor],
        [self.overlay.mp_safeBottomAnchor constraintEqualToAnchor:self.mp_safeBottomAnchor],
        [self.overlay.mp_safeTrailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor]
    ]];
}

- (BOOL)wasTapped {
    return self.overlay.wasTapped;
}

- (void)hideControls {
    [self.overlay hideControls];
}

- (void)showCloseButton {
    [self.overlay showCloseButton];
}

- (void)hideOverlay {
    self.overlay.hidden = YES;
}

#pragma mark - UIView Override

- (void)didMoveToWindow
{
    [super didMoveToWindow];

    if ([self.webAdDelegate respondsToSelector:@selector(adContainerView:didMoveToWindow:)]) {
        [self.webAdDelegate adContainerView:self didMoveToWindow:self.window];
    }
}

#pragma mark - Private: Companion Ad

- (void)preloadCompanionAd {
    MPVASTCompanionAd *ad = [self.videoConfig companionAdForContainerSize:self.bounds.size];
    if (ad == nil) {
        return;
    }

    // If a companion ad is already loaded, don't load another one
    if (self.companionAdView != nil) {
        return;
    }

    self.companionAdView = [[MPVASTCompanionAdView alloc] initWithCompanionAd:ad];
    self.companionAdView.delegate = self;
    self.companionAdView.clipsToBounds = YES;
    [self insertSubview:self.companionAdView belowSubview:self.overlay];
    self.companionAdView.translatesAutoresizingMaskIntoConstraints = NO;

    // All companion ad types may pin to the edges of the container.
    [NSLayoutConstraint activateConstraints:@[
        [self.companionAdView.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor],
        [self.companionAdView.mp_safeLeadingAnchor constraintEqualToAnchor:self.mp_safeLeadingAnchor],
        [self.companionAdView.mp_safeBottomAnchor constraintEqualToAnchor:self.mp_safeBottomAnchor],
        [self.companionAdView.mp_safeTrailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor]
    ]];

    [self.companionAdView setHidden:YES]; // hidden by default, only show after loaded and video finishes
    [self.companionAdView loadCompanionAd]; // delegate will handle load status updates
}

/**
 Note: Do nothing before the video finishes.
 */
- (void)showCompanionAd {
    // Notify UI that contraints and layout need to be updated
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];

    // make companion ad view transparent but unhidden
    self.companionAdView.alpha = 0;
    [self.companionAdView setHidden:NO];
    [UIView animateWithDuration:kAnimationTimeInterval animations:^{
        self.companionAdView.alpha = 1;
        self.videoPlayerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.videoPlayerView removeFromSuperview];
        self.videoPlayerView = nil;
    }];

    // Hide the CTA and enable touch passthrough to the end card.
    self.overlay.clickthroughType = MPAdOverlayClickthroughTypePassthrough;

    // companion ad and industry icon are mutually exclusive
    [self.overlay hideIndustryIcon];

    [self.videoPlayerDelegate videoPlayer:self didShowCompanionAdView:self.companionAdView];
}

/**
 Make the video blurry if there is no companion ad to show after the video finishes.
 */
- (void)makeVideoBlurry {
    // No need to blur more than once
    if (self.blurEffectView != nil) {
        return;
    }

    // If the video finished by playing all the way through, we don't need
    // to do anything special with the video playback.
    if (!self.isVideoFinished) {
        self.isVideoFinished = YES;
        [self.videoPlayerView pauseVideo];
        [self.videoPlayerView skipToEnd];
    }

    self.blurEffectView = [MPViewableVisualEffectView new];
    [self.videoPlayerView addSubview:self.blurEffectView];

    // Safeguard against edge case crash where videoPlayerView is nil or off view hierarchy. see ADF-5838
    if (self.videoPlayerView == nil || self.videoPlayerView.window == nil) {
        return;
    }
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.blurEffectView.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor],
        [self.blurEffectView.mp_safeLeadingAnchor constraintEqualToAnchor:self.mp_safeLeadingAnchor],
        [self.blurEffectView.mp_safeBottomAnchor constraintEqualToAnchor:self.mp_safeBottomAnchor],
        [self.blurEffectView.mp_safeTrailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor]
    ]];

    [UIView animateWithDuration:kAnimationTimeInterval animations:^{
        self.blurEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }];
}

#pragma mark - Creative Experiences

- (void)startAdExperience {
    if (self.adExperienceState != MPAdExperienceStateNotStarted) {
        return;
    }

    self.adExperienceState = MPAdExperienceStateStarted;

    self.elapsedAdTimeStopwatch = [[MPStopwatch alloc] init];
    [self.elapsedAdTimeStopwatch start];

    self.adIndex = 0;
    [self startAd];
}

- (void)startAd {
    NSTimeInterval countdownTime = [self countdownTimeForCurrentAdIndex];

    if (countdownTime > 0) {
        MPCreativeExperienceAdSettings *settings = (self.adIndex < self.creativeExperienceSettings.adSettings.count ? self.creativeExperienceSettings.adSettings[self.adIndex] : nil);
        [self.overlay delayForDuration:countdownTime
                    showCountdownTimer:settings.showCountdownTimer
                   countdownTimerDelay:settings.countdownTimerDelay];
    } else {
        [self didFinishCountdown];
    }
}

- (void)didFinishCountdown {
    if ([self shouldShowSkipButton]) {
        // Once we've finished the countdown, show the skip button.
        // For VAST ads, we'll automatically move to the end card once
        // the video ends, so we don't need to do anything else here.
        [self.overlay showSkipButton];
    } else {
        [self finishAdExperience];
    }
}

- (void)finishAdExperience {
    if (self.adExperienceState != MPAdExperienceStateStarted) {
        return;
    }

    self.adExperienceState = MPAdExperienceStateFinished;

    [self.overlay showCloseButton];

    // Call this in here and not in showCloseButton, as showCloseButton
    // is called in the case that an ad fails to load.
    [self.delegate containerViewAdExperienceDidFinish:self];
}

/*
 Call to advance to the end card, or blurred last frame of a video if there
 is no end card.
 Note: This should only ever be called for video ads, since for non-video
 ads there will never be a next ad or blurred last frame.
 */
- (void)nextAd {
    // nextAd should never be called unless this is a video ad.
    if (![self isVideoAd]) {
        return;
    }

    // Don't do anything if we're already on the end card or blurred last frame.
    if (self.adIndex > 0) {
        return;
    }

    self.adIndex += 1;

    if (self.videoConfig.hasCompanionAd
        && self.companionAdView != nil
        && self.companionAdView.isLoaded
        && self.companionAdView.isHidden) {
        [self showCompanionAd];

        // Start the next ad before stopping the video, as the video
        // duration is still required for the formulas.
        [self startAd];

        // Skipping the video with an end card should stop playback.
        // This is required since the Viewability tracker may hold onto the `videoPlayer`
        // reference after the fullscreen has dismissed (causing the audio playback of the
        // video player to continue).
        [self.videoPlayerView stopVideo];
    } else {
        // We don't want to stop the video if there's no end card, since the
        // blurred last frame will continue to be shown until the user closes the ad.
        [self makeVideoBlurry];

        // There is never a countdown when there is no end card, so just
        // finish the ad experience.
        [self finishAdExperience];
    }
}

- (NSTimeInterval)countdownTimeForCurrentAdIndex {
    NSTimeInterval countdownTime = 0;
    NSTimeInterval elapsedTime = self.elapsedAdTimeStopwatch.duration;

    // Determine the countdown time based on the ad type.
    if (self.videoConfig != nil) {
        NSTimeInterval videoDuration = self.videoPlayerView.videoDuration;
        MPVASTResource *endCard = [self.videoConfig companionAdForContainerSize:self.bounds.size].resourceToDisplay;
        MPCreativeExperienceSettingsEndCardType endCardType = MPCreativeExperienceSettingsEndCardTypeNone;

        if (endCard != nil) {
            if (endCard.type == MPVASTResourceType_HTML) {
                endCardType = MPCreativeExperienceSettingsEndCardTypeInteractive;
            } else {
                endCardType = MPCreativeExperienceSettingsEndCardTypeStatic;
            }
        }

        countdownTime = [self.creativeExperienceSettings countdownTimeFor:videoDuration endCardType:endCardType index:self.adIndex elapsedTime:elapsedTime];
    } else {
        countdownTime = [self.creativeExperienceSettings countdownTimeFor:self.adIndex elapsedTime:elapsedTime];
    }

    return countdownTime;
}

- (BOOL)isVideoAd {
    return self.videoConfig != nil;
}

- (BOOL)shouldShowSkipButton {
    return self.adIndex == 0 && [self isVideoAd] && !self.isVideoFinished;
}

@end

#pragma mark -

@implementation MPAdContainerView (MPVideoPlayer)


- (instancetype)initWithVideoURL:(NSURL *)videoURL videoConfig:(MPVideoConfig *)videoConfig  {
    if (self = [super init]) {
        _videoConfig = videoConfig;
        MPVideoPlayerView *videoPlayerView = [[MPVideoPlayerView alloc] initWithVideoURL:videoURL
                                                                             videoConfig:videoConfig];
        videoPlayerView.delegate = self;
        self.videoPlayerView = videoPlayerView;
        self.backgroundColor = UIColor.blackColor;

        [self sharedInitializationStepsWithContentView:self.videoPlayerView];

        // Only if the video has a clickthrough URL and non-empty title
        // should we show the CTA button.
        if (self.videoConfig.clickThroughURL.absoluteString.length > 0 && self.videoConfig.callToActionButtonTitle.length > 0) {
            self.overlay.callToActionButtonTitle = self.videoConfig.callToActionButtonTitle;
            self.overlay.clickthroughType = MPAdOverlayClickthroughTypeCallToAction;
        } else {
            // Otherwise do not allow clickthrough during the video.
            self.overlay.clickthroughType = MPAdOverlayClickthroughTypeNone;
        }
    }
    return self;
}

- (void)loadVideo {
    if (self.videoPlayerView.isVideoLoaded) {
        return;
    }

    [self.videoPlayerView loadVideo];
}

- (void)playVideo {
    if (self.videoPlayerView.isVideoPlaying == NO) {
        [self preloadCompanionAd];

        [self startAdExperience];
        [self.videoPlayerView playVideo];
    }
}

- (void)pauseVideo {
    [self pause];
}

- (void)stopVideo {
    [self.videoPlayerView stopVideo];
}

#pragma mark - Timer methods

- (void)pause {
    [self.videoPlayerView pauseVideo];
    [self.elapsedAdTimeStopwatch pause];
    [self.overlay pause];
}

- (void)resume {
    // In the case of a video ad without and end card, we will continue
    // to show the blurred last frame until the user closes the ad.
    // If the video has finished playing, either due to playing all the way through,
    // or due to skip, we don't want to resume playback, as this could trigger
    // additional video complete callbacks.
    if (!self.isVideoFinished) {
        [self.videoPlayerView playVideo];
    }

    [self.elapsedAdTimeStopwatch resume];
    [self.overlay resume];
}

@end

#pragma mark -

@implementation MPAdContainerView (MPAdViewOverlayDelegate)

- (void)adViewOverlay:(MPAdViewOverlay *)overlay didTriggerEvent:(MPVideoEvent)event {
    if ([event isEqualToString:MPVideoEventSkip]) {
        // Don't set isVideoFinished here, as it technically has not finished yet.
        [self nextAd];
    }
    if (self.videoPlayerDelegate != nil) {
        [self.videoPlayerDelegate videoPlayer:self
                              didTriggerEvent:event
                                videoProgress:self.videoPlayerView.videoProgress];
    }
    else if ([event isEqualToString:MPVideoEventClose]) {
        [self.webAdDelegate adContainerViewDidHitCloseButton:self];
    }
}

- (void)adViewOverlayDidFinishCountdown:(MPAdViewOverlay *)overlay {
    [self didFinishCountdown];
}

- (void)industryIconView:(MPVASTIndustryIconView *)iconView
         didTriggerEvent:(MPVASTResourceViewEvent)event {
    switch (event) {
        case MPVASTResourceViewEvent_ClickThrough: {
            [self.videoPlayerDelegate videoPlayer:self
                         didClickIndustryIconView:iconView
                        overridingClickThroughURL:nil];
            break;
        }
        case MPVASTResourceViewEvent_DidLoadView: {
            [self.videoPlayerDelegate videoPlayer:self didShowIndustryIconView:iconView];
            break;
        }
        case MPVASTResourceViewEvent_FailedToLoadView: {
            MPLogError(@"Failed to load industry icon view: %@", iconView.icon);
            break;
        }
    }
}

- (void)industryIconView:(MPVASTIndustryIconView *)iconView
didTriggerOverridingClickThrough:(NSURL *)url {
    [self.videoPlayerDelegate videoPlayer:self
                 didClickIndustryIconView:iconView
                overridingClickThroughURL:url];
}

@end

#pragma mark -

@implementation MPAdContainerView (MPVideoPlayerViewDelegate)

- (void)videoPlayerViewDidLoadVideo:(MPVideoPlayerView *)videoPlayerView {
    [self.videoPlayerDelegate videoPlayerDidLoadVideo:self];
}

- (void)videoPlayerViewDidFailToLoadVideo:(MPVideoPlayerView *)videoPlayerView error:(NSError *)error {
    [self.videoPlayerDelegate videoPlayerDidFailToLoadVideo:self error:error];
}

- (void)videoPlayerViewDidStartVideo:(MPVideoPlayerView *)videoPlayerView duration:(NSTimeInterval)duration {
    [self.videoPlayerDelegate videoPlayerDidStartVideo:self duration:duration];
}

- (void)videoPlayerViewDidCompleteVideo:(MPVideoPlayerView *)videoPlayerView duration:(NSTimeInterval)duration {
    self.isVideoFinished = YES;
    [self nextAd];
    [self.videoPlayerDelegate videoPlayerDidCompleteVideo:self duration:duration];
}

- (void)videoPlayerView:(MPVideoPlayerView *)videoPlayerView
videoDidReachProgressTime:(NSTimeInterval)videoProgress
               duration:(NSTimeInterval)duration {
    [self.videoPlayerDelegate videoPlayer:self
                videoDidReachProgressTime:videoProgress
                                 duration:duration];
}

- (void)videoPlayerView:(MPVideoPlayerView *)videoPlayerView
        didTriggerEvent:(MPVideoEvent)event
          videoProgress:(NSTimeInterval)videoProgress {
    [self.videoPlayerDelegate videoPlayer:self
                          didTriggerEvent:event
                            videoProgress:videoProgress];
}

- (void)videoPlayerView:(MPVideoPlayerView *)videoPlayerView
       showIndustryIcon:(MPVASTIndustryIcon *)icon {
    [self.overlay showIndustryIcon:icon];
}

- (void)videoPlayerViewHideIndustryIcon:(MPVideoPlayerView *)videoPlayerView {
    [self.overlay hideIndustryIcon];
}

- (void)videoPlayerViewAudioInterruptionDidBegin:(id<MPVideoPlayer>)videoPlayer {
    [self.videoPlayerDelegate videoPlayerAudioInterruptionDidBegin:videoPlayer];
}

- (void)videoPlayerViewAudioInterruptionDidEnd:(id<MPVideoPlayer>)videoPlayer {
    [self.videoPlayerDelegate videoPlayerAudioInterruptionDidEnd:videoPlayer];
}

@end

#pragma mark -

@implementation MPAdContainerView (MPVASTCompanionAdViewDelegate)

- (UIViewController *)viewControllerForPresentingModalMRAIDExpandedView {
    return self.videoPlayerDelegate.viewControllerForPresentingModalMRAIDExpandedView;
}

- (void)companionAdView:(MPVASTCompanionAdView *)companionAdView
        didTriggerEvent:(MPVASTResourceViewEvent)event {
    switch (event) {
        case MPVASTResourceViewEvent_ClickThrough: {
            [self.videoPlayerDelegate videoPlayer:self
                          didClickCompanionAdView:companionAdView
                        overridingClickThroughURL:nil];
            break;
        }
        case MPVASTResourceViewEvent_DidLoadView: {
            if (self.isVideoFinished) {
                [self showCompanionAd];
            }
            break;
        }
        case MPVASTResourceViewEvent_FailedToLoadView: {
            MPLogError(@"Failed to load companion ad view: %@", companionAdView.ad);
            [self.companionAdView removeFromSuperview];
            self.companionAdView = nil;
            [self.videoPlayerDelegate videoPlayer:self didFailToLoadCompanionAdView:companionAdView];
            break;
        }
    }
}

- (void)companionAdView:(MPVASTCompanionAdView *)companionAdView
didTriggerOverridingClickThrough:(NSURL *)url {
    [self.videoPlayerDelegate videoPlayer:self
                  didClickCompanionAdView:companionAdView
                overridingClickThroughURL:url];
}

- (void)companionAdViewRequestDismiss:(MPVASTCompanionAdView *)companionAdView {
    [self.videoPlayerDelegate videoPlayer:self companionAdViewRequestDismiss:companionAdView];
}

@end
