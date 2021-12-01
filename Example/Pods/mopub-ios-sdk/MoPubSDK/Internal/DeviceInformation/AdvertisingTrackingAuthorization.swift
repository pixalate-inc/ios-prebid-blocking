//
//  AdvertisingTrackingAuthorization.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import AppTrackingTransparency
import Foundation


@objc(MPAdvertisingTrackingAuthorization)
public final class AdvertisingTrackingAuthorization: NSObject {
    /// IDFA from `ASIdentiferManager`. The all zero IDFA `00000000-0000-0000-0000-000000000000` will be translated to `nil`.
    /// - Note: This is exposed for internal state machine consumption only. Use `DeviceInformation.ifa` for using/passing IDFA values.
    @objc public static dynamic var advertisingIdentifier: String? {
        // Note that per: https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
        // The advertising identifier has a value of 00000000-0000-0000-0000-000000000000 until authorization is granted or when using the Simulator.
        let identifier = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        guard identifier != zeroUUID else { return nil }
        
        // Uppercase the UUID to preserve uniformity of UUIDs with previous iterations of the SDK.
        return identifier.uppercased()
    }
    
    /// Indicates that advertising tracking is allowed.
    @objc public static var isAllowed: Bool {
        if #available(iOS 14.0, *) {
            /*
             As of iOS 14, Apple does not provide an explicit means of checking if the IDFA is available.
             The IDFA may or may not be available with an ATT status of NotDetermined, depending on if
             Apple has decided to enforce ATT as opt-in as they plan to. Therefore, if the ATT status
             is NotDetermined, use the IDFA itself to work out the return value of this method.
             
             `MPConsentManager` depends on this method to detect DoNotTrack consent status. Given that,
             if this method were to use the `ifa` getter to grab the IDFA, which checks `MPConsentManager`
             to verify if IDFA is allowed to be collected, any GDPR status other than explicit_yes, combined
             with a "not_determined" ATT status, would result in `MPConsentManager` mistakenly locking into
             a DNT state. Therefore, check `MPConsentManager`'s `rawIfa` value directly. Note that
             we are only checking if the IDFA is non-nil; IDFA is not collected here and should not ever
             be collected via any means besides the `ifa` getter below (minus special circumstances
             internal to `MPConsentManager`).
            */
            switch Self.status {
            case .authorized:    return true                               // Authorized to track
            case .notDetermined: return Self.advertisingIdentifier != nil  // Allowed to track if an IFA is given back from Apple's API
            default:             return false                              // Not allowed
            }
        }

        // Fall back to the old pre-iOS 14 API.
        return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
    }
    
    /// Current tracking authorization status of the application.
    /// - Note: This is a dynamic computed property to facilitate unit testing.
    @available(iOS 14.0, *)
    static dynamic var status: ATTrackingManager.AuthorizationStatus {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    
    /// A string describing the tracking authorization status if available.
    /// - Note: For iOS 13 and below, this will convert the present `isAdvertisingTrackingEnabled` status
    ///         to a comparable tracking authorization status description.
    @objc public static var statusDescription: String? {
        // For iOS 14+, just convert the tracking authorization status to its description string
        if #available(iOS 14.0, *) {
            switch Self.status {
            case .authorized:    return AuthorizationDescription.authorized
            case .denied:        return AuthorizationDescription.denied
            case .notDetermined: return AuthorizationDescription.notDetermined
            case .restricted:    return AuthorizationDescription.restricted
            default:             return nil
            }
        }
        
        // For iOS 13-, convert DNT status to authorized/denied
        return Self.isAllowed ? AuthorizationDescription.authorized : AuthorizationDescription.denied
    }
}

extension AdvertisingTrackingAuthorization {
    
    /// This is a shim property that corresponds to `AdvertisingTrackingAuthorization.status`, but gives
    /// back the numerical value of the `ATTrackingManager.AuthorizationStatus` enumeration.
    /// The shim is needed because Xcode cannot properly translate `@available(iOS 14.0, *) @objc` into
    /// the correct `API_AVAILABLE(ios 14.0, *)` notation.
    @objc public static var statusValue: UInt {
        guard #available(iOS 14.0, *) else { return 0 }
        
        return Self.status.rawValue
    }
}

fileprivate extension AdvertisingTrackingAuthorization {
    /// App Tracking Transparency description strings.
    struct AuthorizationDescription {
        static let authorized: String    = "authorized"
        static let denied: String        = "denied"
        static let notDetermined: String = "not_determined"
        static let restricted: String    = "restricted"
    }
    
    /// All zero UUID string used for IDFA comparisons.
    static let zeroUUID: String = "00000000-0000-0000-0000-000000000000"
}
