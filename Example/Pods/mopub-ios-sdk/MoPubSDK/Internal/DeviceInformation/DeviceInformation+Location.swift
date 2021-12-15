//
//  DeviceInformation+Location.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import CoreLocation
import Foundation

public extension DeviceInformation {
    // MARK: - Location
    
    /// Flag indicating that location can be queried from `CLLocationManager`. The default value is `true`.
    @objc static var enableLocation = true
    
    /// Current location authorization status.
    @objc static var locationAuthorizationStatus: LocationAuthorizationStatus {
        let status = locationManagerAuthorizationStatus
        let isLocationEnabledInSystem = locationManagerLocationServiceEnabled
        let isLocationAllowedByPublisher = enableLocation
        
        switch status {
        case .notDetermined: return  .notDetermined
        case .restricted: return .restricted
        case .denied: return (isLocationEnabledInSystem ? .userDenied : .settingsDenied)
        case .authorizedWhenInUse: return (isLocationAllowedByPublisher ? .authorizedWhenInUse : .publisherDenied)
        case .authorizedAlways: return (isLocationAllowedByPublisher ? .authorizedAlways : .publisherDenied)
        @unknown default: return .unknown
        }
    }
    
    // Bridge to Obj-C.
    
    @objc static func string(fromLocationAuthorizationStatus status: LocationAuthorizationStatus) -> String? {
        return status.stringValue
    }
    
    /// The last known valid location. This will be `nil` if there is no authorization to acquire the location, or if `enableLocation` has been set to `false`.
    @objc static var lastLocation: CLLocation? {
        // Location has been disabled by the Publisher
        guard enableLocation else {
            return nil
        }
        
        if let freshLocation = locationManager.location {
            let oldTimestamp = cachedLastGoodLocation?.timestamp.timeIntervalSince1970 ?? 0
            if freshLocation.horizontalAccuracy >= 0 && freshLocation.timestamp.timeIntervalSince1970 > oldTimestamp {
                cachedLastGoodLocation = freshLocation
            }
        }
        
        return cachedLastGoodLocation
    }
    
    // Location manager is specified as a dynamic computed property to
    // facilitate unit testing.
    internal static dynamic var locationManager: CLLocationManager {
        // Underlying storage for this value.
        struct Storage {
            static let value: CLLocationManager = {
                let result = CLLocationManager()
                result.desiredAccuracy = kCLLocationAccuracyBest
                return result
            }()
        }
        return Storage.value
    }
    
    // Class property to wrap `CLLocationManager.authorizationStatus` in order to
    // facilitate unit testing.
    internal static dynamic var locationManagerAuthorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    // Class property to wrap `CLLocationManager.locationServicesEnabled` in order to
    // facilitate unit testing.
    internal static dynamic var locationManagerLocationServiceEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // Clears the cached last known good location to facilitate unit testing.
    internal static func clearCachedLastLocation() {
        cachedLastGoodLocation = nil
    }
    
    // Cached last known good location
    private static var cachedLastGoodLocation: CLLocation? = nil
}
