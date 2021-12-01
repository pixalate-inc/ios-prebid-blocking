//
//  SKAdNetworkServerKey.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

/// Ad Server SKAdNetwork response keys
enum SKAdNetworkServerKey: String {
    // Top level keys
    case impressionResponse   = "view"
    case clickResponse        = "click"
    case clickMethod          = "clickmethod"
    case clickDisplayTrackers = "clicktrackers"
    
    // SKAdNetwork shared attribution keys
    case version
    case signature
    case network
    case campaign
    case destinationAppStoreIdentifier = "itunesitem"
    case sourceAppStoreIdentifier      = "sourceapp"
    case nonce
    case timestamp
    
    // SKAdNetwork clickthrough attribution keys
    case fidelityType = "fidelity"
    
    // SKAdNetwork viewthrough attribution keys
    case adType          = "adtype"
    case adDescription   = "addescription"
    case adPurchaserName = "purchasername"
}

/// Allow SKAdNetworkServerKey enum cases to be used in dictionary subscripts
extension Dictionary where Key == String {
    subscript(key: SKAdNetworkServerKey) -> Value? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
}
