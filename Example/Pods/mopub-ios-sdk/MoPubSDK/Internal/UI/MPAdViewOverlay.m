//
//  MPAdViewOverlay.m
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAdViewOverlay.h"
#import "MPAdViewOverlay+Private.h"
#import "MPCountdownTimerView.h"
#import "MPGlobal.h"
#import "MPLogging.h"
#import "MPVASTConstant.h"
#import "MPVideoPlayer.h"
#import "MPViewableButton.h"
#import "UIButton+MPAdditions.h"
#import "UIImage+MPAdditions.h"
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

static CGFloat const kRectangleButtonPadding = 16;
static CGFloat const kSkipButtonDimension = 50; // 50x50, same size as the Close button


#pragma mark -

@interface MPAdViewOverlay (MPVASTIndustryIconViewDelegate) <MPVASTIndustryIconViewDelegate>
@end

#pragma mark -

@implementation MPAdViewOverlay

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self stopTimer];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Close Button
        _closeButton = [MPViewableButton buttonWithType:UIButtonTypeCustom
                                        obstructionType:MPViewabilityObstructionTypeClose
                                        obstructionName:MPViewabilityObstructionNameCloseButton];
        _closeButton.backgroundColor = [UIColor clearColor];
        _closeButton.accessibilityLabel = @"Close ad";
        _closeButton.translatesAutoresizingMaskIntoConstraints = NO; // use Autolayout
        [_closeButton addTarget:self action:@selector(didHitCloseButton:) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:[UIImage imageForAsset:kMPImageAssetCloseButton] forState:UIControlStateNormal];
        [self addSubview:_closeButton];

        [[self.closeButton.mp_safeWidthAnchor constraintEqualToConstant:kMPAdViewCloseButtonSize.width] setActive:YES];
        [[self.closeButton.mp_safeHeightAnchor constraintEqualToConstant:kMPAdViewCloseButtonSize.height] setActive:YES];
        [[self.closeButton.mp_safeTrailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor] setActive:YES];
        [[self.closeButton.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor] setActive:YES];

        // Skip Button
        self.skipButton = [MPViewableButton buttonWithType:UIButtonTypeCustom
                                           obstructionType:MPViewabilityObstructionTypeMediaControls
                                           obstructionName:MPViewabilityObstructionNameSkipButton];
        self.skipButton.accessibilityLabel = @"Skip Button";
        [self.skipButton addTarget:self action:@selector(didHitSkipButton) forControlEvents:UIControlEventTouchUpInside];
        [self.skipButton setImage:[UIImage imageForAsset:kMPImageAssetSkipButton] forState:UIControlStateNormal];

        [self addSubview:self.skipButton];
        self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
        [[self.skipButton.topAnchor constraintEqualToAnchor:self.mp_safeTopAnchor] setActive:YES];
        [[self.skipButton.trailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor] setActive:YES];
        [[self.skipButton.widthAnchor constraintEqualToConstant:kSkipButtonDimension] setActive:YES];
        [[self.skipButton.heightAnchor constraintEqualToConstant:kSkipButtonDimension] setActive:YES];

        // Clickthrough
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleClickThrough)];
        tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:tapGestureRecognizer];
        self.clickThroughGestureRecognizer = tapGestureRecognizer;

        MPViewableButton *button = [MPViewableButton buttonWithType:UIButtonTypeCustom
                                                    obstructionType:MPViewabilityObstructionTypeOther
                                                    obstructionName:MPViewabilityObstructionNameCallToActionButton];

        button.accessibilityLabel = @"Call To Action Button";
        [button addTarget:self action:@selector(handleClickThrough) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:button];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [[button.bottomAnchor constraintEqualToAnchor:self.mp_safeBottomAnchor constant:-kRectangleButtonPadding] setActive:YES];
        [[button.trailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor constant:-kRectangleButtonPadding] setActive:YES];
        self.callToActionButton = button;

        // Set control and clickthrough state after all controls have been
        // configured.
        self.controlState = MPAdOverlayControlStateNone;
        self.clickthroughType = MPAdOverlayClickthroughTypePassthrough;
    }
    return self;
}

#pragma mark - Controls

- (void)hideControls {
    self.controlState = MPAdOverlayControlStateNone;
}

- (void)setControlState:(MPAdOverlayControlState)controlState {
    _controlState = controlState;

    switch(self.controlState) {
        case MPAdOverlayControlStateNone:
            self.closeButton.hidden = true;
            self.skipButton.hidden = true;
            // Since the countdown timer needs to be recreated every time
            // it is shown, invalidate it in all cases when we are showing
            // a different control.
            [self stopTimer];
            break;
        case MPAdOverlayControlStateCountdown:
            self.closeButton.hidden = true;
            self.skipButton.hidden = true;
            break;
        case MPAdOverlayControlStateSkipButton:
            self.closeButton.hidden = true;
            self.skipButton.hidden = false;
            [self stopTimer];
            break;
        case MPAdOverlayControlStateCloseButton:
            self.closeButton.hidden = false;
            self.skipButton.hidden = true;
            [self stopTimer];
            break;
    }
}

- (void)delayForDuration:(NSTimeInterval)duration showCountdownTimer:(BOOL)showCountdownTimer countdownTimerDelay:(NSTimeInterval)countdownTimerDelay {
    // Stop any existing countdown timer in the case that we are going
    // from showing the countdown timer for one ad immediately into a
    // countdown timer for another ad.
    [self stopTimer];

    __weak __typeof__(self) weakSelf = self;
    MPCountdownTimerView *timerView = [[MPCountdownTimerView alloc] initWithDuration:duration timerCompletion:^(BOOL hasElapsed) {
        [weakSelf.delegate adViewOverlayDidFinishCountdown:weakSelf];
    }];

    // With user interaction disabled, when the user touches the timer,
    // the tap gesture recognizer's touch.view comes back as the overlay
    // and not the timer. This is fixed by enabling user interaction on the timer.
    [timerView setUserInteractionEnabled:YES];
    self.timerView = timerView;

    [self addSubview:timerView];
    timerView.translatesAutoresizingMaskIntoConstraints = NO;
    [[timerView.topAnchor constraintEqualToAnchor:self.mp_safeTopAnchor] setActive:YES];
    [[timerView.trailingAnchor constraintEqualToAnchor:self.mp_safeTrailingAnchor] setActive:YES];

    // If the timer delay is longer than the duration, treat this the same
    // as not showing the countdown timer.
    if (countdownTimerDelay >= duration) {
        showCountdownTimer = NO;
    }

    if (showCountdownTimer) {
        if (countdownTimerDelay > 0) {
            self.timerView.hidden = YES;

            __weak __typeof__(self) weakSelf = self;
            self.countdownDelayTimer = [[MPResumableTimer alloc] initWithInterval:countdownTimerDelay
                                                                          repeats:NO
                                                                      runLoopMode:NSDefaultRunLoopMode
                                                                          closure:^(MPResumableTimer *timer) {
                weakSelf.timerView.hidden = NO;
            }];
            [self.countdownDelayTimer scheduleNow];
        }
    } else {
        self.timerView.hidden = YES;
    }

    [timerView start];

    self.controlState = MPAdOverlayControlStateCountdown;
}

#pragma mark - UIView Override

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    _wasTapped = YES;

    /*
     When the video is playing, this overlay intercepts all touch events. After the video is
     finished, we might need to pass through the touch events to the companion ad underneath,
     unless the touch events happen upon the overlay subviews, such as the Close button.
     */
    if (self.clickthroughType == MPAdOverlayClickthroughTypePassthrough) {
        for (UIView *subview in self.subviews) {
            if (subview.isHidden == NO
                && subview.alpha > 0
                && subview.userInteractionEnabled
                && [subview pointInside:[self convertPoint:point toView:subview] withEvent:event]) {
                return YES; // let the subview handle the event
            }
        }
        return NO; // no subview can handle it, pass through
    } else {
        return YES; // let this overlay handle the event (with a tap gesture recognizer)
    }
}

- (void)handleClickThrough {
    [self.delegate adViewOverlay:self didTriggerEvent:MPVideoEventClick];
}

- (void)setClickthroughType:(MPAdOverlayClickthroughType)clickthroughType {
    _clickthroughType = clickthroughType;

    // Since pointInside handles the passthrough case, all we need to do
    // here handle the CTA case.
    self.clickThroughGestureRecognizer.enabled = (clickthroughType == MPAdOverlayClickthroughTypeCallToAction);
    self.callToActionButton.hidden = (clickthroughType != MPAdOverlayClickthroughTypeCallToAction);
}

- (void)setCallToActionButtonTitle:(NSString *)callToActionButtonTitle {
    _callToActionButtonTitle = callToActionButtonTitle;

    [self.callToActionButton applyMPVideoPlayerBorderedStyleWithTitle:self.callToActionButtonTitle];
}

#pragma mark - Private: Skip Button

- (void)showSkipButton {
    self.controlState = MPAdOverlayControlStateSkipButton;
}

- (void)didHitSkipButton {
    [self.delegate adViewOverlay:self didTriggerEvent:MPVideoEventSkip];
}

#pragma mark - Timer Control

- (void)pause {
    [self.timerView pause];
    [self.countdownDelayTimer pause];
}

- (void)resume {
    [self.timerView resume];
    [self.countdownDelayTimer scheduleNow];
}

- (void)stopTimer {
    [self.timerView stopAndSignalCompletion:NO];
    [self.timerView removeFromSuperview];
    self.timerView = nil;

    [self.countdownDelayTimer invalidate];
    self.countdownDelayTimer = nil;
}

#pragma mark - Private: Close Button

- (void)didHitCloseButton:(UIButton *)button {
    [self.delegate adViewOverlay:self didTriggerEvent:MPVideoEventClose];
}

- (void)showCloseButton {
    self.controlState = MPAdOverlayControlStateCloseButton;
}

#pragma mark - Industry Icon

- (void)showIndustryIcon:(MPVASTIndustryIcon *)icon {
    if (self.iconView == nil) {
        self.iconView = [MPVASTIndustryIconView new];
        self.iconView.iconViewDelegate = self;
        self.iconViewWidthConstraint = [self.iconView.mp_safeWidthAnchor constraintEqualToConstant:icon.width];
        self.iconViewHeightConstraint = [self.iconView.mp_safeHeightAnchor constraintEqualToConstant:icon.height];

        [self addSubview:self.iconView];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [[self.iconView.mp_safeTopAnchor constraintEqualToAnchor:self.mp_safeTopAnchor] setActive:YES];
        [[self.iconView.mp_safeLeadingAnchor constraintEqualToAnchor:self.mp_safeLeadingAnchor] setActive:YES];
        [self.iconViewWidthConstraint setActive:YES];
        [self.iconViewHeightConstraint setActive:YES];
    } else {
        // if the icon view already exists, update the width and height
        self.iconViewWidthConstraint.constant = icon.width;
        self.iconViewHeightConstraint.constant = icon.height;
    }

    [self.iconView setHidden:YES]; // hidden by default, only show after loaded
    [self.iconView loadIcon:icon]; // delegate will handle load status updates
}

- (void)hideIndustryIcon {
    [self.iconView setHidden:YES];
}

#pragma mark - MPViewabilityObstruction

- (MPViewabilityObstructionType)viewabilityObstructionType {
    return MPViewabilityObstructionTypeNotVisible;
}

- (MPViewabilityObstructionName)viewabilityObstructionName {
    return MPViewabilityObstructionNameOverlay;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Ignore touches on the countdown timer (or any subview), since they
    // do not count as clickthroughs.
    return ![touch.view isDescendantOfView:self.timerView];
}

@end

#pragma mark -

@implementation MPAdViewOverlay (MPVASTIndustryIconViewDelegate)

- (void)industryIconView:(MPVASTIndustryIconView *)iconView
         didTriggerEvent:(MPVASTResourceViewEvent)event {
    switch (event) {
        case MPVASTResourceViewEvent_ClickThrough: {
            break; // no op
        }
        case MPVASTResourceViewEvent_DidLoadView: {
            [self.iconView setHidden:NO];
            break;
        }
        case MPVASTResourceViewEvent_FailedToLoadView: {
            [self.iconView removeFromSuperview];
            self.iconView = nil;
            break;
        }
    }

    [self.delegate industryIconView:iconView didTriggerEvent:event];
}

- (void)industryIconView:(MPVASTIndustryIconView *)iconView
didTriggerOverridingClickThrough:(NSURL *)url {
    [self.delegate industryIconView:iconView didTriggerOverridingClickThrough:url];
}

@end
