//
//  PXViewController.m
//  prebid-blocking
//
//  Created by Pixalate on 11/23/2021.
//  Copyright (c) 2021 Pixalate. All rights reserved.
//

#import "PXViewController.h"
#import <PXBlocking/PXBlocking.h>
#import <MoPubSDK/MoPub.h>

NSString* const APP_UNIT_ID = @"0ac59b0996d947309c33f59d6676399f";
const CGFloat AD_SIZE_WIDTH = 320;
const CGFloat AD_SIZE_HEIGHT = 50;

@interface PXViewController ()

@property(nonatomic) MPAdView *adView;

@end

@implementation PXViewController

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog( @"Finished loading ad" );
}

- (void)loadAd {
    self.adView = [[MPAdView alloc] initWithAdUnitId:APP_UNIT_ID];
    self.adView.delegate = self;
    
    self.adView.frame = CGRectMake( (self.view.bounds.size.width - AD_SIZE_WIDTH)/2, 100,
                                   AD_SIZE_WIDTH, AD_SIZE_HEIGHT);
    
    [self.view addSubview:self.adView];
    [self.adView loadAd];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    MPMoPubConfiguration* mopubConfig = [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:APP_UNIT_ID];
    
    mopubConfig.globalMediationSettings = @[];
    mopubConfig.loggingLevel = MPBLogLevelNone;
    
    [MoPub.sharedInstance initializeSdkWithConfiguration:mopubConfig completion:^{
        [PXBlocking requestBlockStatusWithBlockingMode:PXBlockingModeDefault handler:^(BOOL block, NSError *error) {
            if( error != nil ) {
                // An error occurred in the request. (authentication, internet connectivity issues, etc.)
                NSLog( @"%@", error );

                // It may make the most sense to simply try to continue loading the ad in this situation.

                [self loadAd];
                return;
            }

            if( block ) {
                // Traffic is above the threshold and should be blocked.
                NSLog( @"Ad load was blocked." );
            } else {
                // Traffic is below the threshold and can be allowed.
                NSLog( @"Ad load was allowed." );

                // Ad loading code could go here.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadAd];
                });
            }
        }];
        
//        [Pixalate requestBlockStatus:params responseHandler:^(BOOL block, NSError* error) {
//
//            if( error != nil ) {
//                // An error occurred in the request. (authentication, internet connectivity issues, etc.)
//                NSLog( @"%@", error );
//
//                // It may make the most sense to simply try to continue loading the ad in this situation.
//
//                [self loadAd];
//                return;
//            }
//
//            if( block ) {
//                // Traffic is above the threshold and should be blocked.
//                NSLog( @"Ad load was blocked." );
//            } else {
//                // Traffic is below the threshold and can be allowed.
//                NSLog( @"Ad load was allowed." );
//
//                // Ad loading code could go here.
//                [self loadAd];
//            }
//        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
