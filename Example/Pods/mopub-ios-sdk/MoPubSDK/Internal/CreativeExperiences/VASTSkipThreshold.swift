//
//  VASTSkipThreshold.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// A data model that can be used to determine if and when a VAST video is skippable.
@objc(MPVASTSkipThreshold)
public class VASTSkipThreshold: NSObject, Codable {
    /// Default skip thresholds to use for non-rewarded ad units.
    static let defaultValue = VASTSkipThreshold(skipMin: Defaults.Nonrewarded.skipMin, skipAfter: Defaults.Nonrewarded.skipAfter)
    
    /// Default skip thresholds to use for rewarded ad units.
    static let defaultValueRewarded = VASTSkipThreshold(skipMin: Defaults.Rewarded.skipMin, skipAfter: Defaults.Rewarded.skipAfter)
    
    /// The minimum duration in seconds that a VAST video must be in order for it to be considered
    /// skippable.
    @objc public let skipMin: TimeInterval
    
    /// If a VAST video is at least `skipMin` seconds long, the minimum duration in seconds that
    /// the user must wait before they can skip the video.
    @objc public let skipAfter: TimeInterval
    
    internal init(skipMin: TimeInterval, skipAfter: TimeInterval) {
        self.skipMin = skipMin
        self.skipAfter = skipAfter
    }
    
    public required init(from decoder: Decoder) throws {
        let isRewarded = decoder.userInfo[CreativeExperienceSettings.isRewardedUserInfoKey] as? Bool ?? false
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Using `try? decode` instead of `try decodeIfPresent`, as `decodeIfPresent`
        // will fail if the value is present, but the incorrect type.
        if let skipMin = try? container.decode(TimeInterval.self, forKey: CodingKeys.skipMin), skipMin >= 0 {
            self.skipMin = skipMin
        } else {
            self.skipMin = (isRewarded ? Defaults.Rewarded.skipMin : Defaults.Nonrewarded.skipMin)
        }
        
        if let skipAfter = try? container.decode(TimeInterval.self, forKey: CodingKeys.skipAfter), skipAfter >= 0 {
            self.skipAfter = skipAfter
        } else {
            self.skipAfter = (isRewarded ? Defaults.Rewarded.skipAfter : Defaults.Nonrewarded.skipAfter)
        }
    }
}

// MARK: - CodingKeys
private extension VASTSkipThreshold {
    enum CodingKeys: String, CodingKey {
        case skipMin = "min"
        case skipAfter = "after"
    }
}

// MARK: - Default Values
private extension VASTSkipThreshold {
    struct Defaults {
        struct Rewarded {
            /// The default skip minimum in seconds for non-rewarded ad units.
            static let skipMin: TimeInterval = 0
            
            /// The default skip after in seconds for non-rewarded ad units.
            static let skipAfter: TimeInterval = 30
        }
        
        struct Nonrewarded {
            /// The default skip minimum in seconds for non-rewarded ad units.
            static let skipMin: TimeInterval = 16
            
            /// The default skip after in seconds for non-rewarded ad units.
            static let skipAfter: TimeInterval = 5
        }
    }
}
