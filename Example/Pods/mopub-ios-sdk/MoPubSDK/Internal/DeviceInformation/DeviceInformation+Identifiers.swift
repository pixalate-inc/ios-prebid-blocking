//
//  DeviceInformation+Identifiers.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

public extension DeviceInformation {
    // MARK: - Identifiers
    
    /// An IDFA from `ASIdentiferManager` if it's allowed by `isAdvertisingTrackingEnabled` and `canCollectPersonalInfo`.
    /// Otherwise the value will be `nil`.
    /// - Note: The all zero IDFA `00000000-0000-0000-0000-000000000000` will be translated to `nil`.
    @objc static var ifa: String? {
        /*
         Regardless of if `isAdvertisingTrackingEnabled` returns `true`, provided that `canCollectPersonalInfo`
         is `true`, go ahead and collect the IDFA if it's available. This ensures that even if APIs change in
         the future, the IDFA will always be included when available. iOS will restrict access when it is not
         available.
        */
        if (MPConsentManager.shared().canCollectPersonalInfo) {
            return Self.rawIfa
        }
        
        return nil
    }
    
    /// The vendor's identifier from `UIDevice`.
    @objc static var ifv: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    /// Return the MoPub identifier.
    /// - Note: The identifier does not rotate as of version 5.14.0 and is not considered PII.
    @objc static var mopubIdentifier: String {
        // Cached MoPub identifier doesn't exist.
        guard var identifier = UserDefaults.standard.string(forKey: UserDefaultsKey.mopubIdentifier) else {
            // Generate the MoPub ID and cache it in `UserDefaults`
            let newIdentifier = UUID().uuidString.uppercased()
            UserDefaults.standard.setValue(newIdentifier, forKey:  UserDefaultsKey.mopubIdentifier)
            return newIdentifier
        }
        
        // Upgrade previous MoPub IDs which had the mopub: prefix and remove it.
        // Also remove the previous timestamp since it is no longer relevant.
        if identifier.hasPrefix(mopubPrefixToRemove) {
            identifier = String(identifier.dropFirst(mopubPrefixToRemove.count))
            
            UserDefaults.standard.setValue(identifier, forKey: UserDefaultsKey.mopubIdentifier)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.deprecatedMoPubIdentifierLastSet)
        }
        
        return identifier
    }
    
    /// Retrieves the raw IFA value from `AdvertisingTrackingAuthorization.advertisingIdentifier`.
    /// - Note: This is a dynamic computed property to facilitate unit testing.
    internal static dynamic var rawIfa: String? {
        return AdvertisingTrackingAuthorization.advertisingIdentifier
    }
}

fileprivate extension DeviceInformation {
    // MARK: - Constants
    
    /// MoPub identifiers up to version 5.14.0 included the `mopub:` prefix, which should be
    /// removed when migrating to version 5.14.0+.
    static let mopubPrefixToRemove: String = "mopub:"
    
    /// `UserDefaults` keys.
    struct UserDefaultsKey {
        /// MoPub identifier.
        static let mopubIdentifier: String = "com.mopub.identifier"
        
        /// Deprecated starting in version 5.14.0
        static let deprecatedMoPubIdentifierLastSet: String = "com.mopub.identifiertime"
    }
}
