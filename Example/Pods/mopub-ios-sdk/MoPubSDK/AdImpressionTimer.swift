//
//  AdImpressionTimer.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation
import UIKit


@objc(MPAdImpressionTimer)
public final class AdImpressionTimer: NSObject {
    public typealias Completion = (UIView) -> Void
    
    /// The amount of time required for an impression.
    @objc public let impressionTime: TimeInterval
    
    /// The mode for tracking view visibility.
    let trackingMode: ViewVisibilityTrackingMode
    
    
    @objc public var pixelsRequiredForViewVisibility: CGFloat {
        if case .pixels(let pixels) = trackingMode {
            return pixels
        }
        
        return 0.0
    }
    
    
    @objc public var percentageRequiredForViewVisibility: CGFloat {
        if case .percentage(let percentage) = trackingMode {
            return percentage
        }
        
        return 0.0
    }
    
    // MARK: - Private Properties
    fileprivate let completion: Completion
    
    fileprivate var timer: ResumableTimer?
    
    /// The view for which visibility is being tracked.
    fileprivate weak var view: UIView?
    
    /// The timestamp that the `view` was first visible, or `nil` if `view` is not visible.
    fileprivate var firstVisibilityTimestamp: TimeInterval?
    
    /// Initializes and returns an object that can be used to track the visibility of a view for a given
    /// amount of time.
    /// - Parameters:
    ///     - impressionTime: The amount of time the view must be visible on screen to register
    ///     an impression. The impression will never fire less than 0.1 seconds from the time `startTracking`
    ///     is called.
    ///     - trackingMode: The mode for determining if a view is on visible on screen.
    ///     - completion: The completion block to call for tracking the impression.
    init(impressionTime: TimeInterval, trackingMode: ViewVisibilityTrackingMode, completion: @escaping Completion) {
        self.impressionTime = impressionTime
        self.trackingMode = trackingMode
        self.completion = completion
        
        super.init()
        
        timer = ResumableTimer(interval: Constants.impressionTimerInterval, repeats: true, closure: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.tick()
        })
    }
    
    
    @objc public convenience init(impressionTime: TimeInterval, requiredViewVisibilityPixels: CGFloat, completion: @escaping Completion) {
        self.init(impressionTime: impressionTime, trackingMode: .pixels(requiredViewVisibilityPixels), completion: completion)
    }
    
    @objc public convenience init(impressionTime: TimeInterval, requiredViewVisibilityPercentage: CGFloat, completion: @escaping Completion) {
        self.init(impressionTime: impressionTime, trackingMode: .percentage(requiredViewVisibilityPercentage), completion: completion)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    /// Starts tracking a view based on the `trackingMode` given in `init`.
    /// - Parameter view: The view to track.
    @objc public func startTracking(view: UIView) {
        // Ensure that the timer is in the ready state. Once we start tracking,
        // any subsequent calls to startTracking will be no-ops.
        guard let timer = timer,
              case .ready = timer.state else {
            return
        }
        
        self.view = view
        timer.scheduleNow()
    }
}

// MARK: - Testing
internal extension AdImpressionTimer {
    // isViewVisible is specified as dynamic and internal to facilitate unit testing.
    dynamic static func isViewVisible(_ view: UIView, trackingMode: ViewVisibilityTrackingMode) -> Bool {
        return view.isVisible(for: trackingMode)
    }
    
    // isAppActive is specified as dynamic and internal to facilitate unit testing.
    dynamic static var isAppActive: Bool {
        return UIApplication.shared.applicationState == .active
    }
}

// MARK: - Private
private extension AdImpressionTimer {
    struct Constants {
        /// Unit is in seconds.
        static let impressionTimerInterval: TimeInterval = 0.1
    }
    
    func tick() {
        guard let view = view else {
            // If the view becomes nil, invalidate the timer.
            timer?.invalidate()
            timer = nil
            return
        }
        
        let isViewVisible = Self.isViewVisible(view, trackingMode: trackingMode)
        let isAppActive = Self.isAppActive
        
        guard isViewVisible && isAppActive else {
            // Reset the visibility timestamp if the view goes from visible
            // to not visible.
            firstVisibilityTimestamp = nil
            return
        }
        
        let now = Date().timeIntervalSinceReferenceDate
        
        guard let timestamp = firstVisibilityTimestamp else {
            // Set the timestamp if this is the first tick that this
            // view is visible.
            firstVisibilityTimestamp = now
            return
        }
        
        // Once the view has been visible for `impressionTime`,
        // call our completion block.
        if now - timestamp >= impressionTime {
            fire(with: view)
        }
    }
    
    func fire(with view: UIView) {
        // Ensure the timer is still active when we fire. After we fire
        // once, the timer is invalidated, and so any subsequent calls to
        // fire will be no-ops.
        guard let timer = timer,
              case .active = timer.state else {
            return
        }
        
        timer.invalidate()
        self.timer = nil
        
        completion(view)
    }
}
