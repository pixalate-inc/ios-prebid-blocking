//
//  MPAdViewOverlay+Private.h
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
#import "MPViewableButton.h"
#import "MPCountdownTimerView.h"

@class MPResumableTimer;

typedef NS_ENUM(NSUInteger, MPAdOverlayControlState) {
    /// No control is being shown.
    MPAdOverlayControlStateNone,

    /// A countdown timer is being shown (whether hidden or not).
    MPAdOverlayControlStateCountdown,

    /// The skip button is being shown.
    MPAdOverlayControlStateSkipButton,

    /// The close button is being shown.
    MPAdOverlayControlStateCloseButton,
};

@interface MPAdViewOverlay () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIGestureRecognizer *clickThroughGestureRecognizer;

// UI elements that are considered friendly Viewability obstructions.
// All of the views must conform to `MPViewabilityObstruction`.
@property (nonatomic, strong) MPViewableButton *callToActionButton; // located at the bottom-right corner
@property (nonatomic, strong) MPViewableButton *closeButton; // located at the top-right corner by default, created during `init`
@property (nonatomic, strong) MPViewableButton *skipButton; // located at the top-right corner
@property (nonatomic, strong) MPVASTIndustryIconView *iconView; // located at the top-left corner
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *closeButtonConstraints;
@property (nonatomic, strong) NSLayoutConstraint *iconViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *iconViewHeightConstraint;
@property (nonatomic, strong) MPCountdownTimerView *timerView; // located at the top-right corner
@property (nonatomic, assign) MPAdOverlayControlState controlState;
@property (nonatomic, strong) MPResumableTimer *countdownDelayTimer;

@end
