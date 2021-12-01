//
//  CreativeExperiencesManager.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// Manager to cache and retrieve cached `CreativeExperienceSettings` for ad units.
@objc(MPCreativeExperiencesManager)
public class CreativeExperiencesManager: NSObject {
    @objc public static let shared = CreativeExperiencesManager()
    
    private override init() {}
    
    /// Cache `settings` to disk for `adUnitID`.
    /// - Parameter settings: The settings to cache on disk.
    /// - Parameter adUnitID: The ad unit identifier to cache the `settings` for.
    @objc public func cache(settings: CreativeExperienceSettings, for adUnitID: String) {
        let key = key(for: adUnitID)
        
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        
        MPDiskLRUCache.sharedDisk().store(data, forKey: key)
    }
    
    /// Retrieve the cached settings on disk for `adUnitID`.
    ///
    /// This function does not cache the result in memory, and will hit the disk every time it is called.
    /// Consider caching the result in memory if frequent access is needed.
    /// - Parameter adUnitID: The ad unit identifier to fetch settings for.
    /// - Returns: The cached settings for `adUnitID`, or `nil` if no settings are cached.
    @objc public func cachedSettings(for adUnitID: String) -> CreativeExperienceSettings? {
        let key = key(for: adUnitID)
        
        guard let data = MPDiskLRUCache.sharedDisk().retrieveData(forKey: key) else {
            return nil
        }
        
        guard let settings = try? JSONDecoder().decode(CreativeExperienceSettings.self, from: data) else {
            return nil
        }
        
        return settings
    }
}

// MARK: - Private
private extension CreativeExperiencesManager {
    struct Constants {
        static let keyPrefix = "com.mopub.mopub-ios-sdk.creative-experiences.settings"
    }
    
    /// Returns the key to be used for fetching settings from `MPDiskLRUCache` for `adUnitID`.
    /// - Parameter adUnitID: The ad unit identifier to create the cache key for.
    /// - Returns: A key that can be used to store or fetch settings from `MPDiskLRUCache`.
    func key(for adUnitID: String) -> String {
        return "\(Constants.keyPrefix).\(adUnitID)"
    }
}
