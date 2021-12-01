//
//  PXViewController.h
//  prebid-blocking
//
//  Created by Pixalate on 11/23/2021.
//  Copyright (c) 2021 Pixalate. All rights reserved.
//

#import <MoPubSDK/MPAdView.h>

@import UIKit;

@interface PXViewController : UIViewController <MPAdViewDelegate>

-(UIViewController *)viewControllerForPresentingModalView;
-(void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize;

-(void)loadAd;

@end
