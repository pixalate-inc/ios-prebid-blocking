//
//  EndCardDurations.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// A data model that contains values for end cards to be used in the creative experiences formulas.
@objc(MPEndCardDurations)
public class EndCardDurations: NSObject, Codable {
    /// Default end card durations to use for non-rewarded ad units.
    static let defaultValue = EndCardDurations(staticEndCardExperienceDuration: Defaults.Nonrewarded.staticEndCardExperienceDuration,
                                               interactiveEndCardExperienceDuration: Defaults.Nonrewarded.interactiveEndCardExperienceDuration,
                                               minStaticEndCardDuration: Defaults.Nonrewarded.minStaticEndCardDuration,
                                               minInteractiveEndCardDuration: Defaults.Nonrewarded.minInteractiveEndCardDuration)
    
    /// Default end card durations to use for rewarded ad units.
    static let defaultValueRewarded = EndCardDurations(staticEndCardExperienceDuration: Defaults.Rewarded.staticEndCardExperienceDuration,
                                                       interactiveEndCardExperienceDuration: Defaults.Rewarded.interactiveEndCardExperienceDuration,
                                                       minStaticEndCardDuration: Defaults.Rewarded.minStaticEndCardDuration,
                                                       minInteractiveEndCardDuration: Defaults.Rewarded.minInteractiveEndCardDuration)
    
    /// The amount of time in seconds to factor into the overall ad experience duration when a static
    /// end card is present.
    @objc public let staticEndCardExperienceDuration: TimeInterval
    
    /// The amount of time in seconds to factor into the overall ad experience duration when an interactive
    /// end card is present.
    @objc public let interactiveEndCardExperienceDuration: TimeInterval
    
    /// The minimum amount of time in seconds that a static end card will be shown before to the user
    /// before they can perform the next action (e.g. close the ad).
    @objc public let minStaticEndCardDuration: TimeInterval
    
    /// The minimum amount of time in seconds that an interactive end card will be shown before to the user
    /// before they can perform the next action (e.g. close the ad).
    @objc public let minInteractiveEndCardDuration: TimeInterval
    
    internal init(staticEndCardExperienceDuration: TimeInterval,
                  interactiveEndCardExperienceDuration: TimeInterval,
                  minStaticEndCardDuration: TimeInterval,
                  minInteractiveEndCardDuration: TimeInterval) {
        self.staticEndCardExperienceDuration = staticEndCardExperienceDuration
        self.interactiveEndCardExperienceDuration = interactiveEndCardExperienceDuration
        self.minStaticEndCardDuration = minStaticEndCardDuration
        self.minInteractiveEndCardDuration = minInteractiveEndCardDuration
    }
    
    public required init(from decoder: Decoder) throws {
        let isRewarded = decoder.userInfo[CreativeExperienceSettings.isRewardedUserInfoKey] as? Bool ?? false
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Using `try? decode` instead of `try decodeIfPresent`, as `decodeIfPresent`
        // will fail if the value is present, but the incorrect type.
        if let staticEndCardExperienceDuration = try? container.decode(TimeInterval.self, forKey: CodingKeys.staticEndCardExperienceDuration), staticEndCardExperienceDuration >= 0 {
            self.staticEndCardExperienceDuration = staticEndCardExperienceDuration
        } else {
            self.staticEndCardExperienceDuration = (isRewarded ? Defaults.Rewarded.staticEndCardExperienceDuration : Defaults.Nonrewarded.staticEndCardExperienceDuration)
        }
        
        if let interactiveEndCardExperienceDuration = try? container.decode(TimeInterval.self, forKey: CodingKeys.interactiveEndCardExperienceDuration), interactiveEndCardExperienceDuration >= 0 {
            self.interactiveEndCardExperienceDuration = interactiveEndCardExperienceDuration
        } else {
            self.interactiveEndCardExperienceDuration = (isRewarded ? Defaults.Rewarded.interactiveEndCardExperienceDuration : Defaults.Nonrewarded.interactiveEndCardExperienceDuration)
        }
        
        if let minStaticEndCardDuration = try? container.decode(TimeInterval.self, forKey: CodingKeys.minStaticEndCardDuration), minStaticEndCardDuration >= 0 {
            self.minStaticEndCardDuration = minStaticEndCardDuration
        } else {
            self.minStaticEndCardDuration = (isRewarded ? Defaults.Rewarded.minStaticEndCardDuration : Defaults.Nonrewarded.minStaticEndCardDuration)
        }
        
        if let minInteractiveEndCardDuration = try? container.decode(TimeInterval.self, forKey: CodingKeys.minInteractiveEndCardDuration), minInteractiveEndCardDuration >= 0 {
            self.minInteractiveEndCardDuration = minInteractiveEndCardDuration
        } else {
            self.minInteractiveEndCardDuration = (isRewarded ? Defaults.Rewarded.minInteractiveEndCardDuration : Defaults.Nonrewarded.minInteractiveEndCardDuration)
        }
    }
}

// MARK: - CodingKeys
private extension EndCardDurations {
    enum CodingKeys: String, CodingKey {
        case staticEndCardExperienceDuration = "static"
        case interactiveEndCardExperienceDuration = "interactive"
        case minStaticEndCardDuration = "min_static"
        case minInteractiveEndCardDuration = "min_interactive"
    }
}

// MARK: - Default Values
private extension EndCardDurations {
    struct Defaults {
        struct Rewarded {
            /// The default time in seconds for the static end card experience duration for rewarded
            /// ad units.
            static let staticEndCardExperienceDuration: TimeInterval = 5
            
            /// The default time in seconds for the interactive end card experience duration for
            /// rewarded ad units.
            static let interactiveEndCardExperienceDuration: TimeInterval = 10
            
            /// The default time in seconds for the minimum static end card duration for rewarded
            /// ad units.
            static let minStaticEndCardDuration: TimeInterval = 0
            
            /// The default time in seconds for the minimum interactive static end card duration for
            /// rewarded ad units.
            static let minInteractiveEndCardDuration: TimeInterval = 0
        }
        
        struct Nonrewarded {
            /// The default time in seconds for the static end card experience duration for
            /// non-rewarded ad units.
            static let staticEndCardExperienceDuration: TimeInterval = 0
            
            /// The default time in seconds for the interactive end card experience duration for
            /// non-rewarded ad units.
            static let interactiveEndCardExperienceDuration: TimeInterval = 0
            
            /// The default time in seconds for the minimum static end card duration for
            /// non-rewarded ad units.
            static let minStaticEndCardDuration: TimeInterval = 0
            
            /// The default time in seconds for the minimum interactive static end card duration for
            /// non-rewarded ad units.
            static let minInteractiveEndCardDuration: TimeInterval = 0
        }
    }
}
