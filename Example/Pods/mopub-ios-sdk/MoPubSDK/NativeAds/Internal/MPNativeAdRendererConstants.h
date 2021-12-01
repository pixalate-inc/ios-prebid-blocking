//
//  MPNativeAdRendererConstants.h
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

/**
  Return this value from `MPNativeViewSizeHandler` when you want to display ad content that could
  have variable height and needs to be calculated only after ad properties are available. The
  implementation of ad view conforming to the `MPNativeAdRendering` protocol should implement
  `sizeThatFits:` and handle layout changes appropriately.
 */
FOUNDATION_EXPORT const CGFloat MPNativeViewFrameBasedDynamicDimension;

/**
  Return this value from `MPNativeViewSizeHandler` when you want to display ad content that could
  have variable height and needs to be calculated only after ad properties are available. The
  implementation of ad view conforming to the `MPNativeAdRendering` protocol should rely on Auto Layout (i.e. set constraints such that systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority is handled properly).
 */
FOUNDATION_EXPORT const CGFloat MPNativeViewAutoLayoutBasedDynamicDimension;
