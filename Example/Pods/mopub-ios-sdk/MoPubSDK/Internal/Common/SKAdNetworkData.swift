//
//  SKAdNetworkData.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation
import StoreKit


/// Model class to hold an SKAdNetwork server response.
@objc(MPSKAdNetworkData)
public class SKAdNetworkData: NSObject {
    
    /// Enumeration defining possible click methods
    @objc (MPSKAdNetworkDataClickMethod)
    public enum ClickMethod: UInt {
        case interceptAppStoreClicks = 0
        case interceptAllClicks      = 1
    }
    
    /// Initialize `SKAdNetworkData` with an `skadn` server response
    @objc public required init?(serverResponse: [String: Any]?) {
        // Ensure we are running at least iOS 14
        guard #available(iOS 14.0, *) else {
            return nil
        }
        
        // Ensure server response is non-nil
        guard let serverResponse = serverResponse else {
            return nil
        }
        
        // Set click data
        // Validate click data exists, and base (SKAdNetwork 2.0) required fields exist and can be converted
        guard let serverClickDataDictionary = serverResponse[.clickResponse] as? [String: String],
              let version            = serverClickDataDictionary[.version],
              let networkIdentifier  = serverClickDataDictionary[.network],
              let campaignIdentifier = serverClickDataDictionary[.campaign]?.unsignedNSNumber,
              let destinationApp     = serverClickDataDictionary[.destinationAppStoreIdentifier]?.unsignedNSNumber,
              let nonce              = UUID(uuidString: serverClickDataDictionary[.nonce] ?? ""),
              let sourceApp          = serverClickDataDictionary[.sourceAppStoreIdentifier]?.unsignedNSNumber,
              let timestamp          = serverClickDataDictionary[.timestamp]?.unsignedNSNumber,
              let signature          = serverClickDataDictionary[.signature]
        else {
            // Invalidate response if click data does not exist or if required keys aren't included
            return nil
        }
        // Make click data dictionary
        var localClickDataDict: [String: Any] = [
            SKStoreProductParameterAdNetworkVersion:                  version,
            SKStoreProductParameterAdNetworkIdentifier:               networkIdentifier,
            SKStoreProductParameterAdNetworkCampaignIdentifier:       campaignIdentifier,
            SKStoreProductParameterITunesItemIdentifier:              destinationApp,
            SKStoreProductParameterAdNetworkNonce:                    nonce,
            SKStoreProductParameterAdNetworkSourceAppStoreIdentifier: sourceApp,
            SKStoreProductParameterAdNetworkTimestamp:                timestamp,
            SKStoreProductParameterAdNetworkAttributionSignature:     signature,
        ]
        // Fidelity-type may or may not exist (required field for SKAdNetwork 2.2, but we support 2.0+)
        localClickDataDict[SKAdNetworkData.fidelityTypeKey] = serverClickDataDictionary[.fidelityType]?.unsignedNSNumber
        // Set click data dictionary property
        clickDataDictionary = localClickDataDict
        
        // Set click method
        var localClickMethod: ClickMethod = .interceptAppStoreClicks // Default to `.interceptAppStoreClicks`
        if let clickMethodResponse = serverResponse[.clickMethod] as? String,
           let clickMethodInteger = UInt(clickMethodResponse),
           let clickMethodValue = ClickMethod(rawValue: clickMethodInteger) {
            // If click method can be parsed, use that value
            localClickMethod = clickMethodValue
        }
        clickMethod = localClickMethod
        
        // Set click display trackers
        var localClickDisplayTrackers: [String] = []
        if let clickDisplayTrackersResponse = serverResponse[.clickDisplayTrackers] as? [String] {
            localClickDisplayTrackers = clickDisplayTrackersResponse
        }
        clickDisplayTrackers = localClickDisplayTrackers
        
        // Set impression data if running iOS 14.5, and if that data is available
        var localImpressionDataStorage: AnyObject? = nil
        if #available(iOS 14.5, *) {
            let impressionResponseDictionary = serverResponse[.impressionResponse] as? [String: String]
            localImpressionDataStorage = SKAdImpression(serverResponse: impressionResponseDictionary) ?? nil
        }
        impressionDataStorage = localImpressionDataStorage
        
        // Call super
        super.init()
        
        // Validate click data dictionary (has to be called after `super` because of implicit `self` call)
        guard validate(clickDataDictionary: localClickDataDict) else {
            return nil
        }
    }
    
    /// Defines which clicks will be intercepted to become SKAdNetwork clicks
    @objc public let clickMethod: ClickMethod
    
    /// The click display tracking URLs to be fired after the click URL display type is resolved.
    /// Note: these trackers may contain macros to be replaced, so they are not yet converted to URLs.
    @objc public let clickDisplayTrackers: [String]
    
    /// Dictionary to pass to `SKStoreProductViewController` when initiating an SKAdNetwork click
    @objc public let clickDataDictionary: [String: Any]
    
    /// `SKAdImpression` associated with this ad response if available
    @available(iOS 14.5, *)
    @objc public var impressionData: SKAdImpression? {
        return impressionDataStorage as? SKAdImpression
    }
    
    /// Backing storage for `impressionData`. Swift doesn't like it if you store properties
    /// whose types may or may not be present depending on the OS version directly, so this
    /// is necessary.
    private let impressionDataStorage: AnyObject?
    
    /// Validates the `clickDataDictionary` to ensure it's good for the given SKAdNetwork version
    @available(iOS 14.0, *)
    private func validate(clickDataDictionary: [String: Any]) -> Bool {
        // All the SKAdNetwork 2.0 fields were verified to exist in `init(with:)` so there's no need to check for them here.
        
        // No extra fields need to be verified below iOS <14.5 / SKAdNetwork <2.2. Return `true` if below iOS 14.5
        guard #available(iOS 14.5, *) else {
            return true
        }
        
        // iOS 14.5+:
        
        // Be sure the version number can be parsed into a `Double` or return `false`
        guard let skAdNetworkVersionString = clickDataDictionary[SKStoreProductParameterAdNetworkVersion] as? String,
              let skAdNetworkVersionNumber = Double(skAdNetworkVersionString) else {
            return false
        }
        
        // If the SKAdNetwork version is below 2.2, the current data is valid
        if skAdNetworkVersionNumber < SKAdNetworkData.skAdNetwork22VersionValue {
            return true
        }
        
        // Otherwise, if SKAdNetwork version is >= 2.2, the data is valid if `fidelity-type` exists
        return clickDataDictionary[SKAdNetworkData.fidelityTypeKey] != nil
    }
    
}

/// Extension for constants
fileprivate extension SKAdNetworkData {
    /// Apple doesn't provide a constant for `fidelity-type`, so provide one here
    static let fidelityTypeKey = "fidelity-type"
    
    /// Max supported SKAdNetwork version
    static let skAdNetwork22VersionValue = 2.2
}
