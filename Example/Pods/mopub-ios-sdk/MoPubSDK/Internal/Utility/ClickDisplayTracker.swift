//
//  ClickDisplayTracker.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// Handles macro replacement and firing of trackers fired upon display of the clickthrough.
@objc(MPClickDisplayTracker)
public class ClickDisplayTracker: NSObject {
    
    /// Enumeration of various click display types available (various forms in which clicks can be displayed)
    @objc(MPClickDisplayTrackerDisplayType)
    public enum DisplayType: UInt {
        case safariViewController = 0
        case nativeSafari
        case storeProductViewController
        case error
    }
    
    /// Tracks the click display trackers for the given `skAdNetworkData` with the given `displayType`
    /// Multiple `trackClickDisplay` calls with a single `skAdNetworkData` instance will result in only the
    /// first call being tracked -- subsequent calls will do nothing.
    /// `nil` `skAdNetworkData` will do nothing.
    @objc public class func trackClickDisplay(skAdNetworkData: SKAdNetworkData?, displayType: DisplayType) {
        // Ensure skAdNetworkData is non-nil
        guard let skAdNetworkData = skAdNetworkData else {
            return
        }
        
        // Call `trackClickDisplay` with the shared instance of `MPAnalyticsTracker`
        trackClickDisplay(skAdNetworkData: skAdNetworkData,
                          displayType: displayType,
                          analyticsTracker: MPAnalyticsTracker.shared())
    }
    
    /// Tracks the click display trackers for the given `skAdNetworkData` with the given `displayType`
    /// using the given `analyticsTracker`. Enables the injection of a custom `analyticsTracker` for testing.
    /// Multiple `trackClickDisplay` calls with a single `skAdNetworkData` instance will result in only the
    /// first call being tracked -- subsequent calls will do nothing.
    class func trackClickDisplay(skAdNetworkData: SKAdNetworkData,
                                 displayType: DisplayType,
                                 analyticsTracker: MPAnalyticsTrackerProtocol) {
        // Ensure the passed in `skAdNetworkData` has not already been tracked
        guard !alreadyTrackedSkAdNetworkDataObjects.contains(skAdNetworkData) else {
            return
        }
        
        // Marked the passed in `skAdNetworkData` as tracked
        alreadyTrackedSkAdNetworkDataObjects.add(skAdNetworkData)
        
        // With each URL string in `skAdNetworkData`'s `clickDisplayTrackers`, replace the macro, then
        // convert the URL string into an actual URL, discarding any strings that don't convert to URLs.
        let trackingURLs = skAdNetworkData.clickDisplayTrackers
            .map { $0.replacingOccurrences(of: macroReplacementString, with: displayType.description) }
            .compactMap { URL(string: $0) }
        
        // Then, send tracking requests to each of the URLs
        analyticsTracker.sendTrackingRequest(for: trackingURLs)
    }
    
    /// Set of weak references to already-tracked skAdNetworkData objects
    private static let alreadyTrackedSkAdNetworkDataObjects = NSHashTable<SKAdNetworkData>.weakObjects()
}

/// Extension for constants
fileprivate extension ClickDisplayTracker {
    /// The string server sends in click display URLs to be replaced
    private static let macroReplacementString = "%%SDK_CLICK_TYPE%%"
}

/// Provides the string that is used in the URL macro for a given case
extension ClickDisplayTracker.DisplayType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .safariViewController: return "in_app_browser"
        case .nativeSafari: return "native_browser"
        case .storeProductViewController: return "app_store"
        case .error: return "error"
        }
    }
}

/// Provides the ability to iterate through all cases
extension ClickDisplayTracker.DisplayType: CaseIterable {}
