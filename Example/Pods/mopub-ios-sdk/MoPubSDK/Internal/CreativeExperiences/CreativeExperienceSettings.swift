//
//  CreativeExperienceSettings.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// Creative experience settings for an overall ad experience.
@objc(MPCreativeExperienceSettings)
public class CreativeExperienceSettings: NSObject, Codable {
    static let isRewardedUserInfoKey = CodingUserInfoKey(rawValue: "isRewarded")!
    
    /// Default creative experience settings for rewarded ad units.
    @objc public static let defaultValue = CreativeExperienceSettings(settingsHash:nil,
                                                                      maxAdExperienceTime: Defaults.Nonrewarded.maxAdExperienceTime,
                                                                      vastSkipThresholds: Defaults.Nonrewarded.vastSkipThresholds,
                                                                      endCardDurations: Defaults.Nonrewarded.endCardDurations,
                                                                      mainAd: Defaults.Nonrewarded.mainAd,
                                                                      endCard: Defaults.Nonrewarded.endCard)
    
    /// Default creative experience settings for rewarded ad units.
    @objc public static let defaultValueRewarded = CreativeExperienceSettings(settingsHash:nil,
                                                                              maxAdExperienceTime: Defaults.Rewarded.maxAdExperienceTime,
                                                                              vastSkipThresholds: Defaults.Rewarded.vastSkipThresholds,
                                                                              endCardDurations: Defaults.Rewarded.endCardDurations,
                                                                              mainAd: Defaults.Rewarded.mainAd,
                                                                              endCard: Defaults.Rewarded.endCard)
    
    /// Objective-C helper to decode a `CreativeExperienceSettings` object from an NSDictionary.
    @objc public static func decode(from dictionary: NSDictionary?, isRewarded: Bool) -> CreativeExperienceSettings? {
        guard let dictionary = dictionary else {
            return nil
        }
        
        guard let json = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.userInfo[isRewardedUserInfoKey] = isRewarded
        return try? decoder.decode(CreativeExperienceSettings.self, from: json)
    }
    
    /// The hash value for these settings as calculated by ad server, or `nil` if using the default
    /// values.
    @objc public let settingsHash: String?
    
    /// The maximum duration in seconds of this ad experience.
    @objc public let maxAdExperienceTime: TimeInterval
    
    /// Thresholds to use to determine the skippability of any VAST ads in this ad experience.
    @objc public let vastSkipThresholds: [VASTSkipThreshold]
    
    /// Durations to be used in the formulas in determining
    /// ad experience duration for any end cards in this ad experience.
    @objc public let endCardDurations: EndCardDurations
    
    /// An array of settings for each individual ad within the ad experience.
    @objc public var adSettings: [CreativeExperienceAdSettings] {
        return [mainAd, endCard]
    }
    
    /// We have to have underlying storage for the main ad and end card objects in order to use coding keys.
    private let mainAd: CreativeExperienceAdSettings
    private let endCard: CreativeExperienceAdSettings
    
    internal init(settingsHash: String?,
                 maxAdExperienceTime: TimeInterval,
                 vastSkipThresholds: [VASTSkipThreshold],
                 endCardDurations: EndCardDurations,
                 mainAd: CreativeExperienceAdSettings,
                 endCard: CreativeExperienceAdSettings) {
        self.settingsHash = settingsHash
        self.maxAdExperienceTime = maxAdExperienceTime
        self.vastSkipThresholds = vastSkipThresholds
        self.endCardDurations = endCardDurations
        self.mainAd = mainAd
        self.endCard = endCard
    }
    
    public required init(from decoder: Decoder) throws {
        let isRewarded = decoder.userInfo[Self.isRewardedUserInfoKey] as? Bool ?? false
        let container = try decoder.container(keyedBy: CodingKeys.self)
    
        // Using `try? decode` instead of `try decodeIfPresent`, as `decodeIfPresent`
        // will fail if the value is present, but the incorrect type.
        settingsHash = try? container.decode(String.self, forKey: CodingKeys.settingsHash)
        
        if let maxAdExperienceTime = try? container.decode(TimeInterval.self, forKey: .maxAdExperienceTime), maxAdExperienceTime > 0 {
            self.maxAdExperienceTime = maxAdExperienceTime
        } else {
            self.maxAdExperienceTime = (isRewarded ? Defaults.Rewarded.maxAdExperienceTime : Defaults.Nonrewarded.maxAdExperienceTime)
        }
        
        if let vastSkipThresholds = try? container.decode([VASTSkipThreshold].self, forKey: .vastSkipThresholds), vastSkipThresholds.count > 0 {
            self.vastSkipThresholds = vastSkipThresholds
        } else {
            self.vastSkipThresholds = (isRewarded ? [VASTSkipThreshold.defaultValueRewarded] : [VASTSkipThreshold.defaultValue])
        }
        
        if let endCardDurations = try? container.decode(EndCardDurations.self, forKey: CodingKeys.endCardDurations) {
            self.endCardDurations = endCardDurations
        } else {
            self.endCardDurations = (isRewarded ? Defaults.Rewarded.endCardDurations : Defaults.Nonrewarded.endCardDurations)
        }
        
        if let mainAd = try? container.decode(CreativeExperienceAdSettings.self, forKey: CodingKeys.mainAd) {
            self.mainAd = mainAd
        } else {
            self.mainAd = (isRewarded ? Defaults.Rewarded.mainAd : Defaults.Nonrewarded.mainAd)
        }
        
        if let endCard = try? container.decode(CreativeExperienceAdSettings.self, forKey: CodingKeys.endCard) {
            self.endCard = endCard
        } else {
            self.endCard = (isRewarded ? Defaults.Rewarded.endCard : Defaults.Nonrewarded.endCard)
        }
    }
}

// MARK: - CodingKeys
private extension CreativeExperienceSettings {
    enum CodingKeys: String, CodingKey {
        case settingsHash = "hash"
        case maxAdExperienceTime = "max_ad_time_secs"
        case vastSkipThresholds = "video_skip_thresholds_secs"
        case endCardDurations = "ec_durs_secs"
        case mainAd = "main_ad"
        case endCard = "end_card"
    }
}

// MARK: - Default Values
private extension CreativeExperienceSettings {
    struct Defaults {
        struct Rewarded {
            /// The default max ad experience time in seconds for rewarded ad units.
            static let maxAdExperienceTime: TimeInterval = 30
            
            /// The default VAST skip thresholds for rewarded ad units.
            static let vastSkipThresholds = [VASTSkipThreshold.defaultValueRewarded]
            
            /// The default end card durations for rewarded ad units.
            static let endCardDurations = EndCardDurations.defaultValueRewarded
            
            /// The default main ad settings for rewarded ad units.
            static let mainAd = CreativeExperienceAdSettings.defaultValueRewarded
            
            // Intentionally using the defaultValue instead of defaultValueRewarded
            // for the end card.
            /// The default end card settings for rewarded ad units.
            static let endCard = CreativeExperienceAdSettings.defaultValue
        }
        
        struct Nonrewarded {
            /// The default max ad experience time in seconds for non-rewarded ad units.
            static let maxAdExperienceTime: TimeInterval = 0
            
            /// The default VAST skip thresholds for non-rewarded ad units.
            static let vastSkipThresholds = [VASTSkipThreshold.defaultValue]
            
            /// The default end card durations for non-rewarded ad units.
            static let endCardDurations = EndCardDurations.defaultValue
            
            /// The default main ad settings for non-rewarded ad units.
            static let mainAd = CreativeExperienceAdSettings.defaultValue
            
            /// The default end card settings for non-rewarded ad units.
            static let endCard = CreativeExperienceAdSettings.defaultValue
        }
    }
}
