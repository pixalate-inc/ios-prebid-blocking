//
//  MPFullscreenAdViewController.m
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPError.h"
#import "MPFullscreenAdViewController+MRAIDWeb.h"
#import "MPFullscreenAdViewController+Private.h"
#import "MPFullscreenAdViewController+Video.h"
#import "MPFullscreenAdViewController+Web.h"
#import "MPLogging.h"
#import "MPVASTCompanionAd.h"

@interface MPFullscreenAdViewController (MPVASTResourceViewDelegate) <MPVASTResourceViewDelegate>
@end

#pragma mark -

@implementation MPFullscreenAdViewController

#pragma mark - API

- (void)setVideoPlayerDelegate:(id<MPVideoPlayerDelegate>)videoPlayerDelegate {
    self.adContainerView.videoPlayerDelegate = videoPlayerDelegate;
}

- (instancetype)initWithAdContentType:(MPAdContentType)adContentType {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationFullScreen; // different from the iOS 13+ default
        _adContentType = adContentType;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentFromViewController:(UIViewController *)viewController complete:(void(^)(NSError * _Nullable))complete {
    if (self.presentingViewController) {
        if (complete != nil) {
            complete(NSError.fullscreenAdAlreadyOnScreen);
        }
        return;
    }

    // Notify any listeners that presentation of the view controller
    // is about to begin.
    [self viewControllerWillPresent];

    __typeof__(self) __weak weakSelf = self;
    [viewController presentViewController:self animated:MP_ANIMATED completion:^{
        __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        switch (strongSelf.adContentType) {
            case MPAdContentTypeUndefined:
            case MPAdContentTypeVideo: {
                // intentional `switch` fallthrough: no op, countdown timer is controlled by the video player logic
                break;
            }
            case MPAdContentTypeImage:
            case MPAdContentTypeWebNoMRAID:
            case MPAdContentTypeWebWithMRAID:
                // intentional `switch` fallthrough for web and image ads
                [strongSelf.adContainerView startAdExperience];
                break;
        }

        // Notify any listeners that presentation of the view controller
        // is complete.
        [self viewControllerDidPresent];

        if (complete != nil) {
            complete(nil);
        }
    }];
}

- (void)dismiss {
    [self viewControllerWillDismiss];
    [self dismissViewControllerAnimated:MP_ANIMATED completion:^{
        [self viewControllerDidDismiss];
    }];
}

- (void)showCloseButton {
    [self.adContainerView showCloseButton];
}

- (void)setCreativeExperienceSettings:(MPCreativeExperienceSettings *)creativeExperienceSettings {
    _creativeExperienceSettings = creativeExperienceSettings;
    self.adContainerView.creativeExperienceSettings = creativeExperienceSettings;
}

#pragma mark - Override

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.adContentType == MPAdContentTypeWebWithMRAID
        && [[UIApplication sharedApplication] mp_supportsOrientationMask:self.supportedOrientationMask]) {
        return self.supportedOrientationMask;
    }

    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
        case MPAdContentTypeImage:
        case MPAdContentTypeVideo: {
            return super.supportedInterfaceOrientations;
        }
        case MPAdContentTypeWebNoMRAID: // intentional `switch` fallthrough for web ads
        case MPAdContentTypeWebWithMRAID: {
            NSUInteger applicationSupportedOrientations =
            [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:MPKeyWindow()];
            NSUInteger interstitialSupportedOrientations = applicationSupportedOrientations;
            NSString *orientationDescription = @"any";

            // Using the _orientationType, narrow down the supported interface orientations.

            if (_orientationType == MPInterstitialOrientationTypePortrait) {
                interstitialSupportedOrientations &=
                (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
                orientationDescription = @"portrait";
            } else if (_orientationType == MPInterstitialOrientationTypeLandscape) {
                interstitialSupportedOrientations &= UIInterfaceOrientationMaskLandscape;
                orientationDescription = @"landscape";
            }

            // If the application does not support any of the orientations given by _orientationType,
            // just return the application's supported orientations.

            if (!interstitialSupportedOrientations) {
                MPLogInfo(@"Your application does not support this interstitial's desired orientation "
                           @"(%@).", orientationDescription);
                return applicationSupportedOrientations;
            } else {
                return interstitialSupportedOrientations;
            }
        }
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
        case MPAdContentTypeImage:
        case MPAdContentTypeVideo: {
            return super.preferredInterfaceOrientationForPresentation;
        }
        case MPAdContentTypeWebNoMRAID: // intentional `switch` fallthrough for web ads
        case MPAdContentTypeWebWithMRAID: {
            NSUInteger supportedInterfaceOrientations = [self supportedInterfaceOrientations];
            UIInterfaceOrientation currentInterfaceOrientation = MPInterfaceOrientation();
            NSUInteger currentInterfaceOrientationMask = (1 << currentInterfaceOrientation);

            // First, try to display the interstitial using the current interface orientation. If the
            // current interface orientation is unsupported, just use any of the supported orientations.

            if (supportedInterfaceOrientations & currentInterfaceOrientationMask) {
                return currentInterfaceOrientation;
            } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
                return UIInterfaceOrientationPortrait;
            } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskPortraitUpsideDown) {
                return UIInterfaceOrientationPortraitUpsideDown;
            } else if (supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
                return UIInterfaceOrientationLandscapeLeft;
            } else {
                return UIInterfaceOrientationLandscapeRight;
            }
        }
    }
}

- (void)loadView {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break; // no op
        case MPAdContentTypeImage:
            // Intentional fall-through to video logic
        case MPAdContentTypeVideo:
            // Use a `MPAdContainerView` instead of the plain `UIView` for `self.view` because
            // `adContainerView` is allocated in `initWithVideoURL:videoConfig:`
            // Note: do not call `[super loadView]` as explained in Apple doc
            // https://developer.apple.com/documentation/uikit/uiviewcontroller/1621454-loadview
            self.view = self.adContainerView;
            break;
        case MPAdContentTypeWebNoMRAID: // non-MRAID web view is loaded by `MPAdWebViewAgent`
        case MPAdContentTypeWebWithMRAID: // MRAID web view is loaded by `MRController`
            // Intentional `switch` fallthrough.
            // For web ads, `adContainerView` is not allocated during `init`, thus the view is `UIView`.
            self.view = [[UIView alloc] initWithFrame:CGRectZero];
            self.view.backgroundColor = [UIColor blackColor];
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

#pragma mark - View Life Cycle Events

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self fullscreenWebAdWillAppear];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self fullscreenMRAIDWebAdWillAppear];
            break;
    }

    [self.appearanceDelegate fullscreenAdWillAppear:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self fullscreenWebAdDidAppear];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self fullscreenMRAIDWebAdDidAppear];
            break;
    }

    [self.appearanceDelegate fullscreenAdDidAppear:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self fullscreenWebAdWillDisappear];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self fullscreenMRAIDWebAdWillDisappear];
            break;
    }

    [self.appearanceDelegate fullscreenAdWillDisappear:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self fullscreenWebAdDidDisappear];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self fullscreenMRAIDWebAdDidDisappear];
            break;
    }

    [self.appearanceDelegate fullscreenAdDidDisappear:self];
}

#pragma mark - View Controller Life Cycle Events

/**
 Invoked before `presentViewController:animated:completion:`
 */
- (void)viewControllerWillPresent {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            // no op
            break;
        case MPAdContentTypeVideo:
            // no op
            break;
        case MPAdContentTypeImage:
            // no op
            break;
        case MPAdContentTypeWebNoMRAID:
            [self willPresentFullscreenWebAd];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self willPresentFullscreenMRAIDWebAd];
            break;
    }

    [self.appearanceDelegate fullscreenAdWillPresent:self];
}

/**
 Invoked in the completion block of `presentViewController:animated:completion:`
*/
- (void)viewControllerDidPresent {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            // no op
            break;
        case MPAdContentTypeVideo:
            // no op
            break;
        case MPAdContentTypeImage:
            // no op
            break;
        case MPAdContentTypeWebNoMRAID:
            [self didPresentFullscreenWebAd];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self didPresentFullscreenMRAIDWebAd];
            break;
    }

    [self.appearanceDelegate fullscreenAdDidPresent:self];
}

/**
 Invoked before `dismissViewControllerAnimated:completion:`
 */
- (void)viewControllerWillDismiss {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self willDismissFullscreenWebAd];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self willDismissFullscreenMRAIDWebAd];
            break;
    }

    [self.appearanceDelegate fullscreenAdWillDismiss:self];
}

/**
 Invoked in the completion block of `dismissViewControllerAnimated:completion:`
 */
- (void)viewControllerDidDismiss {
    switch (self.adContentType) {
        case MPAdContentTypeUndefined:
            break;
        case MPAdContentTypeVideo:
            break;
        case MPAdContentTypeImage:
            break;
        case MPAdContentTypeWebNoMRAID:
            [self didDismissFullscreenWebAd];
            break;
        case MPAdContentTypeWebWithMRAID:
            [self didDismissFullscreenMRAIDWebAd];
            break;
    }

    [self.appearanceDelegate fullscreenAdDidDismiss:self];
}

#pragma mark - Timer methods

- (void)pause {
    [self.adContainerView pauseVideo];
}

- (void)resume {
    [self.adContainerView resume];
}

#pragma mark - Interruptions

- (void)startInterruption:(MPFullscreenAdInterruption)interruption {
    // Only pause when there are currently no interruptions.
    if (self.interruptions == MPFullscreenAdInterruptionNone) {
        [self pause];
    }

    self.interruptions |= interruption;
}

- (void)endInterruption:(MPFullscreenAdInterruption)interruption {
    // Immediately return if this interruption was not previously pushed.
    if (!(self.interruptions & interruption)) {
        return;
    }

    self.interruptions &= ~interruption;

    // There is an edge case in where foregrounding the app does
    // not trigger a `AVAudioSessionInterruptionNotification` event with
    // `AVAudioSessionInterruptionTypeEnded`. As such the pairing between
    // start and end interruptions for `MPFullscreenAdInterruptionAudio` do
    // not match.
    // This is a workaround for that issue, but removing `MPFullscreenAdInterruptionAudio`
    // from the bitmask if `MPFullscreenAdInterruptionBackground` is encountered.
    // https://developer.apple.com/forums/thread/15514
    if (interruption == MPFullscreenAdInterruptionBackground) {
        self.interruptions &= ~MPFullscreenAdInterruptionAudio;
    }

    // Resume when there are no interruptions left.
    if (self.interruptions == MPFullscreenAdInterruptionNone) {
        [self resume];
    }
}

#pragma mark - Notifications

- (void)appDidEnterBackground:(NSNotification *)notification {
    [self startInterruption:MPFullscreenAdInterruptionBackground];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self endInterruption:MPFullscreenAdInterruptionBackground];
}

@end

#pragma mark -

@implementation MPFullscreenAdViewController (MPAdContainerViewDelegate)

- (void)containerViewAdExperienceDidFinish:(MPAdContainerView *)containerView {
    [self.containerDelegate containerViewAdExperienceDidFinish:containerView];
}

@end
