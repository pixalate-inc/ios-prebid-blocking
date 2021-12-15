//
//  MPAdViewOverlay.h
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>
#import "MPAdViewConstant.h"
#import "MPVASTIndustryIconView.h"
#import "MPViewabilityObstruction.h"
#import "MPViewableView.h"

@class MPAdViewOverlay, MPCreativeExperienceSettings;

typedef NS_ENUM(NSUInteger, MPAdOverlayClickthroughType) {
    /// Disable clickthrough.
    MPAdOverlayClickthroughTypeNone,

    /// Show the CTA button with the title provided in the @c MPAdViewOverlayConfig. This has
    /// no effect if the config or CTA title are @c nil.
    /// Triggers @c MPVideoEventClick event on click.
    MPAdOverlayClickthroughTypeCallToAction,

    /// Pass clicks through to the underlying content view.
    MPAdOverlayClickthroughTypePassthrough
};


NS_ASSUME_NONNULL_BEGIN

@protocol MPAdViewOverlayDelegate <NSObject, MPVASTIndustryIconViewDelegate>

- (void)adViewOverlay:(MPAdViewOverlay *)overlay didTriggerEvent:(MPVideoEvent)event;

- (void)adViewOverlayDidFinishCountdown:(MPAdViewOverlay *)overlay;

@end

/**
 This is an overlay of @c MPAdContainerView for full screen VAST ad, which should be added as the
 top-most subview that covers the whole area of the @c MPAdContainerView. Timer related activities
 are affected by app life cycle events.

 See documentation at https://developers.mopub.com/dsps/ad-formats/video/

 Note: Industry icon placing logic is different from the VAST spec per MoPub video format
 documentation: "We will ignore x/y coordinates for the icon and will always place it in the top
 left corner to ensure a consistent user experience."
 */
@interface MPAdViewOverlay : MPViewableView <MPViewabilityObstruction>

@property (nonatomic, readonly) BOOL wasTapped;
@property (nonatomic, weak) id<MPAdViewOverlayDelegate> delegate;

#pragma mark - Timers
/**
 Pause the timer.
 */
- (void)pause;

/**
 Resume the timer.
*/
- (void)resume;

/**
 Invalidates the timer.
 */
- (void)stopTimer;

#pragma mark - Controls

/**
 Hide the close button, skip button, and countdown timer.
 */
- (void)hideControls;

/**
 Delay for a duration, optionally showing the countdown timer with a delay of its own.
 */
- (void)delayForDuration:(NSTimeInterval)duration showCountdownTimer:(BOOL)showCountdownTimer countdownTimerDelay:(NSTimeInterval)countdownTimerDelay;

/**
 Show the close button.
 */
- (void)showCloseButton;

/**
 Show the skip button.
 */
- (void)showSkipButton;

#pragma mark - Clickthrough

/**
 The clickthrough type for the overlay. Defaults to @c MPAdOverlayClickthroughTypePassthrough.
 */
@property (nonatomic, assign) MPAdOverlayClickthroughType clickthroughType;

/**
 The title for the CTA button.
 */
@property (nonatomic, assign) NSString *callToActionButtonTitle;

#pragma mark - Industry Icon

/**
 Show the industry icon.
 */
- (void)showIndustryIcon:(MPVASTIndustryIcon *)icon;

/**
 Hide the industry icon.
 */
- (void)hideIndustryIcon;

@end

NS_ASSUME_NONNULL_END
