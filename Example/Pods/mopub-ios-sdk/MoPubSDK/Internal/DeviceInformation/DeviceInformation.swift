//
//  DeviceInformation.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation
import CoreTelephony


@objc(MPDeviceInformation)
public final class DeviceInformation: NSObject {
    /// Call upon SDK startup to initalize this class.
    @objc public static func start(completion: @escaping () -> Void) {
        guard isStarted == false else {
            completion()
            return
        }
        
        isStarted = true
        
        DispatchQueue.main.async {
            // It appears that the first access to any CTCarrier property
            // is what takes the longest, so just accessing carrierName caches
            // all of the properties.
            _ = cellularService?.carrier.carrierName
            completion()
        }
    }
    
    private static var isStarted = false
}
 
// MARK: - Application Metadata
public extension DeviceInformation {
    /// The current App Transport Security settings of the device.
    internal static let appTransportSecuritySettings: ATSSetting = {
        // Grab the ATS dictionary from the Info.plist
        // Don't cast the entire dictionary to [String: Bool], just in case
        // the user has some invalid type in the dictionary as well.
        guard let atsSettingsDictionary = Bundle.main.infoDictionary?[Constants.ATS.dictionaryKey] as? [String: Any] else {
            return .enabled
        }
        
        return ATSSetting.setting(from: atsSettingsDictionary)
    }()
    
    // Bridge ATSSetting to Obj-C
    
    @objc static let appTransportSecuritySettingsValue: Int = appTransportSecuritySettings.rawValue
    
    /// The version of the application, as listed in its Info.plist.
    @objc static dynamic var applicationVersion: String? {
        // Underlying storage for this value.
        struct Storage {
            static let value = Bundle.main.infoDictionary?[Constants.bundleVersionKey] as? String
        }
        return Storage.value
    }
}

// MARK: - Connectivity
public extension DeviceInformation {
    /// The current cellular service in use on this device, or nil if the device does not have cellular service.
    /// If the device has muliple cellular services, this picks one of them arbitrarily.
    /// Specified as a dynamic property to facilitate unit testing.
    @objc static dynamic var cellularService = CellularService.services.first
    
    /// The current network status (not reachable, WiFi, 3G, 4G, 5G, etc.)
    /// Logic and comments come from Apple's Reachability sample code in `[Reachability networkStatusForFlags:]` at https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html)
    @objc static var currentNetworkStatus: NetworkStatus {
        // Couldn't create a Reachability reference, return .notReachable
        guard let reachability = reachability else {
            return .notReachable
        }
        
        // Get current flags to determine connection type
        let reachabilityFlags = reachability.reachabilityFlags
        
        // The target host is not reachable.
        guard reachabilityFlags.contains(.reachable) else {
            return .notReachable
        }
        
        var networkStatus: NetworkStatus = .notReachable
        
        if !reachabilityFlags.contains(.connectionRequired) {
            // If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
            networkStatus = .reachableViaWiFi
        }
        
        if reachabilityFlags.contains(.connectionOnDemand) || reachabilityFlags.contains(.connectionOnTraffic) {
            // ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
            if !reachabilityFlags.contains(.interventionRequired) {
                // ... and no [user] intervention is needed...
                networkStatus = .reachableViaWiFi
            }
        }
        
        if reachabilityFlags.contains(.isWWAN), let status = cellularService?.currentRadioAccessTechnology {
            /// ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return status
        }
        
        return networkStatus
    }
    
    /// SCNetworkReachability reference for determining connectivity.
    /// Specified as a dynamic property to facilitate unit testing.
    internal static dynamic var reachability: NetworkReachable? = {
        // Address used to determine connectivity not dependent on a particular host (from Apple's Reachability sample code: https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html)
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            return nil
        }
        
        return reachability
    }()
}

internal protocol NetworkReachable {
    var reachabilityFlags: SCNetworkReachabilityFlags { get }
}

/// Protocol implementation of NetworkReachable
extension SCNetworkReachability: NetworkReachable {
    var reachabilityFlags: SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self, &flags)
        return flags
    }
}

// MARK: - Private
private extension DeviceInformation {
    struct Constants {
        static let bundleVersionKey = "CFBundleShortVersionString"
        
        struct ATS {
            static let dictionaryKey = "NSAppTransportSecurity"
        }
    }
}
