//
//  SKAdImpression+ConvenienceServerResponseInitializer.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import StoreKit

@available(iOS 14.5, *)
extension SKAdImpression {
    
    /// Initialize an `SKAdImpression` object with a server response dictionary
    convenience init?(serverResponse: [String: String]?) {
        guard let serverResponseDictionary = serverResponse else {
            return nil
        }
        
        // Init SKAdImpression
        self.init()
        
        // Required values
        guard let localSignature       = serverResponseDictionary[.signature],
              let localVersion         = serverResponseDictionary[.version],
              let networkIdentifier    = serverResponseDictionary[.network],
              let campaignIdentifier   = serverResponseDictionary[.campaign]?.unsignedNSNumber,
              let advertisedApp        = serverResponseDictionary[.destinationAppStoreIdentifier]?.unsignedNSNumber,
              let impressionIdentifier = serverResponseDictionary[.nonce],
              let sourceApp            = serverResponseDictionary[.sourceAppStoreIdentifier]?.unsignedNSNumber,
              let localTimestamp       = serverResponseDictionary[.timestamp]?.unsignedNSNumber
        else {
            return nil
        }
              
        signature                        = localSignature
        version                          = localVersion
        adNetworkIdentifier              = networkIdentifier
        adCampaignIdentifier             = campaignIdentifier
        advertisedAppStoreItemIdentifier = advertisedApp
        adImpressionIdentifier           = impressionIdentifier
        sourceAppStoreItemIdentifier     = sourceApp
        timestamp                        = localTimestamp
        
        // Optional values
        adType          = serverResponseDictionary[.adType]
        adDescription   = serverResponseDictionary[.adDescription]
        adPurchaserName = serverResponseDictionary[.adPurchaserName]
    }
    
}
