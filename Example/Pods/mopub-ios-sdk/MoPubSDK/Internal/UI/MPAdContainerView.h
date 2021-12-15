//
//  MPAdContainerView.h
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>
#import "MPAdViewConstant.h"
#import "MPVideoPlayer.h"
#import "MPVideoPlayerDelegate.h"
#import "MPVideoPlayerView.h"
#import "MPViewableView.h"
#import "MPWebView.h"

NS_ASSUME_NONNULL_BEGIN

@class MPImageCreativeView;
@class MPCreativeExperienceSettings;

@protocol MPAdContainerViewWebAdDelegate, MPAdContainerViewDelegate;

/**
 This is the unified ad container view for all inline and fullscreen ad formats. Ad content view is
 added as a subview. An overlay with all the accessory views (Close, Skip, Countdown timer, CTA)
 is always also added as a subview. This overlay is always on top of the content view, and is able to
 intercept all touch events before passing to the content view.
 */
@interface MPAdContainerView : MPViewableView

@property (nonatomic, readonly) BOOL wasTapped;
@property (nonatomic, weak) id<MPAdContainerViewWebAdDelegate> webAdDelegate; // only for web ads
@property (nonatomic, weak) id<MPVideoPlayerDelegate> videoPlayerDelegate; // only for video ads
@property (nonatomic, weak) id<MPAdContainerViewDelegate> delegate; // For all ad types
@property (nonatomic, strong) MPCreativeExperienceSettings *creativeExperienceSettings;

/**
 Initializes @c MPAdContainerView to a given frame with a given web content view.

 @param frame The frame of the view
 @param webContentView The web view that will contain the content of the ad
 */
- (instancetype)initWithFrame:(CGRect)frame webContentView:(MPWebView *)webContentView;

/**
 Initializes @c MPAdContainerView to a given frame with a given image content view.

 @param frame The frame of the view
 @param imageCreativeView The image view that will contain the content of the ad
 */
- (instancetype)initWithFrame:(CGRect)frame imageCreativeView:(MPImageCreativeView *)imageCreativeView;

/**
 Hide all controls (e.g. close button, countdown timer, etc).
 */
- (void)hideControls;

/**
 Immediately show the close button.
 */
- (void)showCloseButton;

/**
 Call to start the ad experience. This should not be called in the case of VAST ads, as the ad experience
 will begin automatically when @c playVideo is called.
 */
- (void)startAdExperience;

/**
 Completely hide the overlay.
 Note: This only exists as a fix for MRAID end cards, as MRAID end card content is contained within a
 second container view that has its own overlay, which should not be shown.
 */
- (void)hideOverlay;

@end

#pragma mark -

@interface MPAdContainerView (MPVideoPlayer) <MPVideoPlayer>
@property (nonatomic, readonly) MPVideoPlayerView *videoPlayerView;

/**
 Resumes the ad after an interruption.
 Note: This differs from @c playVideo as @c playVideo is latched and cannot be used to resume
 the video.
 */
- (void)resume;

@end

#pragma mark -

@protocol MPAdContainerViewWebAdDelegate <NSObject>

/**
 For Close button action handling.
 Note: If  @c videoPlayerDelegate is assigned, and @c MPVideoPlayerEvent_Close happens,
 @c MPVideoPlayerDelegate.videoPlayer:didTriggerEvent:videoProgress: is called instead.
 */
- (void)adContainerViewDidHitCloseButton:(MPAdContainerView *)adContainerView;

@optional

/**
 Typically for MRAID two-part ad creative resizing.
 */
- (void)adContainerView:(MPAdContainerView *)adContainerView didMoveToWindow:(UIWindow *)window;

@end

@protocol MPAdContainerViewDelegate <NSObject>

/**
 Called once an ad experience has finished and the close button is shown.
 */
- (void)containerViewAdExperienceDidFinish:(MPAdContainerView *)containerView;

@end


NS_ASSUME_NONNULL_END
