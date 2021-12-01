//
//  UIView+ViewVisibility.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation
import UIKit


public extension UIView {
    /// Determines if this view is visible using `trackingMode`.
    ///
    /// To be considered visible, a view must:
    /// * Not be hidden, or a descendent of a hidden view.
    /// * Intersect the frame of its parent window, even if that intersection has zero area.
    ///
    /// - Parameter trackingMode: The tracking mode to use to determine if this view is visible.
    /// - Returns `true` if this view is currently visible, or `false` if not.
    /// - Note: This function does not check whether any part of the view is obscured by another view.
    internal func isVisible(for trackingMode: ViewVisibilityTrackingMode) -> Bool {
        guard let intersection = visibleRect else {
            return false
        }
        
        let intersectionArea = intersection.width * intersection.height
        
        switch trackingMode {
        case .percentage(let percent):
            let area = bounds.width * bounds.height
            let clampedPercent = percent.clamp(to: 0...1)
            return intersectionArea >= clampedPercent * area
        case .pixels(let pixels):
            let clampedPixels = (pixels < 0 ? 0 : pixels)
            return intersectionArea >= clampedPixels
        }
    }
    
    /// `true` if this view is currently visible, or `false` if not.
    ///
    /// To be considered visible, a view must:
    /// * Not be hidden, or a descendent of a hidden view.
    /// * Intersect the frame of its parent window, even if that intersection has zero area.
    ///
    /// - Note: This function does not check whether any part of the view is obscured by another view.
    @objc var isVisible: Bool {
        return visibleRect != nil
    }
}

// MARK: - Private
private extension UIView {
    /// A `CGRect` that is the visible portion of this view's frame that intersects with its parent window, in the
    /// window's coordinate system, or `nil` if the view is not visible.
    var visibleRect: CGRect? {
        guard let superview = superview else {
            return nil
        }
        
        guard let window = window else {
            return nil
        }
        
        // Ensure that both self and all of our ancestors are not hidden.
        var ancestor: UIView? = self
        
        while let view = ancestor {
            if view.isHidden {
                 return nil
            }
            ancestor = view.superview
        }
        
        // We need to call `convert` on this view's superview rather than on this view itself.
        let viewFrameInWindowCoordinates = superview.convert(frame, to: window)
        
        // Ensure that the view intersects the window. Since we're looking
        // from the reference point of the window, we must use the window's
        // bounds.
        guard viewFrameInWindowCoordinates.intersects(window.bounds) else {
            return nil
        }
        
        return viewFrameInWindowCoordinates.intersection(window.bounds)
    }
}
