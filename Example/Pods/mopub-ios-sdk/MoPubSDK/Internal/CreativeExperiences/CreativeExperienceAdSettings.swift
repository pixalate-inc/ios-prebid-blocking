//
//  CreativeExperienceAdSettings.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation


/// A data model that contains settings for a single ad (e.g. primary ad or end card) within
/// an ad experience.
@objc(MPCreativeExperienceAdSettings)
public class CreativeExperienceAdSettings: NSObject, Codable {
    /// Default ad settings to use for non-rewarded ad units.
    static let defaultValue = CreativeExperienceAdSettings(minTimeUntilNextAction: Defaults.Nonrewarded.minTimeUntilNextAction,
                                                          countdownTimerDelay: Defaults.Nonrewarded.countdownTimerDelay,
                                                          showCountdownTimer: Defaults.Nonrewarded.showCountdownTimer)
    
    /// Default ad settings to use for rewarded ad units.
    static let defaultValueRewarded = CreativeExperienceAdSettings(minTimeUntilNextAction: Defaults.Rewarded.minTimeUntilNextAction,
                                                                   countdownTimerDelay: Defaults.Rewarded.countdownTimerDelay,
                                                                   showCountdownTimer: Defaults.Rewarded.showCountdownTimer)
    
    /// The minimum amount of time in seconds that this ad will be shown to the user before they are allowed
    /// to perform an action (either skip to the next ad, or close the ad experience).
    @objc public let minTimeUntilNextAction: TimeInterval
    
    /// Indicates if the countdown timer should be shown during the `minTimeUntilNextAction`
    /// interval.
    @objc public let showCountdownTimer: Bool
    
    /// If `showCountdownTimer` is `true`, the amount of time in seconds to delay before showing the
    /// the countdown timer. A value of 0 indicates that the timer should be shown immediately.
    @objc public let countdownTimerDelay: TimeInterval
    
    internal init(minTimeUntilNextAction: TimeInterval, countdownTimerDelay: TimeInterval, showCountdownTimer: Bool) {
        self.minTimeUntilNextAction = minTimeUntilNextAction
        self.countdownTimerDelay = countdownTimerDelay
        self.showCountdownTimer = showCountdownTimer
    }

    public required init(from decoder: Decoder) throws {
        let isRewarded = decoder.userInfo[CreativeExperienceSettings.isRewardedUserInfoKey] as? Bool ?? false
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Using `try? decode` instead of `try decodeIfPresent`, as `decodeIfPresent`
        // will fail if the value is present, but the incorrect type.
        if let minTimeUntilNextAction = try? container.decode(TimeInterval.self, forKey: CodingKeys.minTimeUntilNextAction), minTimeUntilNextAction >= 0 {
            self.minTimeUntilNextAction = minTimeUntilNextAction
        } else {
            self.minTimeUntilNextAction = (isRewarded ? Defaults.Rewarded.minTimeUntilNextAction : Defaults.Nonrewarded.minTimeUntilNextAction)
        }
        
        if let countdownTimerDelay = try? container.decode(TimeInterval.self, forKey: CodingKeys.countdownTimerDelay), countdownTimerDelay >= 0 {
            self.countdownTimerDelay = countdownTimerDelay
        } else {
            self.countdownTimerDelay = (isRewarded ? Defaults.Rewarded.countdownTimerDelay : Defaults.Nonrewarded.countdownTimerDelay)
        }
        
        // Show countdown is sent from the server with a value of either 0/1,
        // but it will be re-encoded as a boolean.
        if let showCountdownTimerInt = try? container.decode(Int.self, forKey: CodingKeys.showCountdownTimer), let showCountdownTimer = Bool(integer: showCountdownTimerInt) {
            self.showCountdownTimer = showCountdownTimer
        } else if let showCountdownTimerBool = try? container.decode(Bool.self, forKey: CodingKeys.showCountdownTimer) {
            self.showCountdownTimer = showCountdownTimerBool
        } else {
            self.showCountdownTimer = (isRewarded ? Defaults.Rewarded.showCountdownTimer : Defaults.Nonrewarded.showCountdownTimer)
        }
    }
}

// MARK: - CodingKeys
private extension CreativeExperienceAdSettings {
    enum CodingKeys: String, CodingKey {
        case minTimeUntilNextAction = "min_next_action_secs"
        case countdownTimerDelay = "cd_delay_secs"
        case showCountdownTimer = "show_cd"
    }
}

// MARK: - Default Values
private extension CreativeExperienceAdSettings {
    struct Defaults {
        struct Rewarded {
            /// The default time until next action in seconds if the decoded value is missing or
            /// out of range for rewarded ad units.
            static let minTimeUntilNextAction: TimeInterval = 30
            
            /// The default time to delay showing the countdown timer in seconds if the decoded
            /// value is missing or out of range for rewarded ad units.
            static let countdownTimerDelay: TimeInterval = 0
            
            /// The default value for if the countdown timer should be shown if the decoded
            /// value is missing or out of range for rewarded ad units.
            static let showCountdownTimer = true
        }

        struct Nonrewarded {
            /// The default time until next action in seconds if the decoded value is missing or
            /// out of range for non-rewarded ad units.
            static let minTimeUntilNextAction: TimeInterval = 0
            
            /// The default time to delay showing the countdown timer in seconds if the decoded
            /// value is missing or out of range for non-rewarded ad units.
            static let countdownTimerDelay: TimeInterval = 0
            
            /// The default value for if the countdown timer should be shown if the decoded
            /// value is missing or out of range for non-rewarded ad units.
            static let showCountdownTimer = true
        }
    }
}
