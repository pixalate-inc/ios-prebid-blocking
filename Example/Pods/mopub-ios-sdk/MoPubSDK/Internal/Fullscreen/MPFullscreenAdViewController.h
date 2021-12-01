//
//  MPFullscreenAdViewController.h
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>
#import "MPAdViewConstant.h"
#import "MPGlobal.h"
#import "MPFullscreenAdViewControllerDelegate.h"
#import "MPAdContainerView.h"

@class MPCreativeExperienceSettings;

typedef NS_OPTIONS(NSUInteger, MPFullscreenAdInterruption) {
    /*
     No interruption.
     */
    MPFullscreenAdInterruptionNone          = 0,

    /*
     The ad was interrupted due to the user clicking through.
     */
    MPFullscreenAdInterruptionClickthrough  = 1 << 0,

    /*
     The ad was interrupted due to the user backgrounding the application.
     */
    MPFullscreenAdInterruptionBackground    = 1 << 1,

    /*
     The ad was interrupted due to the audio session being interrupted,
     for example by background audio or a phone call. This only applies
     in the case of VAST ads.
     */
    MPFullscreenAdInterruptionAudio         = 1 << 2
};

NS_ASSUME_NONNULL_BEGIN

/**
 The purpose of this @c MPFullscreenAdViewController protocol is to define the common interface
 between interstitial view controllers without forcing them to subclass @c MPFullscreenAdViewController.

 @c MPFullscreenAdViewController uses @c MPAdContainerView for @c self.view instead of the
 plain @c UIView. All the video playing logics are contained in @c MPVideoPlayerView, and this view
 controller is designed to be a thin container of the video player view. If this view controller
 should have extra functionalities, consider do it in @c MPVideoPlayerView first since the video
 player view is reused as the subview of some other view controller.
 */
@protocol MPFullscreenAdViewController <NSObject>
@end

@interface MPFullscreenAdViewController : UIViewController <MPFullscreenAdViewController>

@property (nonatomic, weak) id<MPFullscreenAdViewControllerAppearanceDelegate> appearanceDelegate;
@property (nonatomic, weak) id<MPAdContainerViewDelegate> containerDelegate;
@property (nonatomic, strong) MPCreativeExperienceSettings *creativeExperienceSettings;

- (instancetype)initWithAdContentType:(MPAdContentType)adContentType;

- (void)presentFromViewController:(UIViewController *)viewController complete:(void(^)(NSError * _Nullable))complete;

- (void)dismiss;

- (void)showCloseButton;

/*
 Call when an interruption begins.
 */
- (void)startInterruption:(MPFullscreenAdInterruption)interruption;

/*
 Call when an interruption ends.
 */
- (void)endInterruption:(MPFullscreenAdInterruption)interruption;

@end

#pragma mark -

@interface MPFullscreenAdViewController (MPAdContainerViewDelegate) <MPAdContainerViewDelegate>
@end

NS_ASSUME_NONNULL_END
