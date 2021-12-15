//
//  ViewVisibilityTrackingMode.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

/// A mode for tracking view visibility.
enum ViewVisibilityTrackingMode {
    /// Track the view by a specific number of pixels on screen.
    case pixels(CGFloat)
    
    /// Track the view by a percentage that is visible on screen.
    case percentage(CGFloat)
}
