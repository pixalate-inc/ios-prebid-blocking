//
//  CreativeExperienceSettings+Formulas.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

public extension CreativeExperienceSettings {
    @objc(MPCreativeExperienceSettingsEndCardType)
    enum EndCardType: Int {
        /// No end card
        case none
        
        /// A non-HTML end card.
        case `static`
        
        /// An HTML end card.
        case interactive
    }
    
    enum AdType {
        case vast(TimeInterval, EndCardType)
        case other
    }
    
    /// Obj-C wrapper for `countdownTime` for VAST ads.
    @objc func countdownTime(for videoDuration: TimeInterval,
                             endCardType: EndCardType,
                             index: Int,
                             elapsedTime: TimeInterval) -> TimeInterval {
        let adType = AdType.vast(videoDuration, endCardType)
        return countdownTime(for: adType, index: index, elapsedTime: elapsedTime)
    }
    
    /// Obj-C wrapper for `countdownTime` for non-VAST ads.
    @objc func countdownTime(for index: Int,
                             elapsedTime: TimeInterval) -> TimeInterval {
        return countdownTime(for: .other, index: index, elapsedTime: elapsedTime)
    }
    
    /// Returns the countdown time for the ad of type `adType` at `index`.
    /// - Parameter adType: The type of ad to calculate the countdown time for.
    /// - Parameter index: The index of the ad in the overall ad experience.
    /// - Parameter elapsedTime: The amount of time that user has spent in the ad experience.
    /// - Returns: The amount of time that the countdown time should be shown for.
    func countdownTime(for adType: AdType, index: Int, elapsedTime: TimeInterval) -> TimeInterval {
        // Always return 0 if the index is out of range of our ad settings.
        guard index >= 0, index < adSettings.count else {
            return 0
        }
        
        let closeAfter: TimeInterval
        let timeUntilNextAction: TimeInterval
        let isLastAd: Bool
        
        switch(adType) {
        case .vast(let videoDuration, let endCardType):
            closeAfter = closeAfterDuration(for: videoDuration, endCardType: endCardType)
            
            // Index is used instead of an explicit main ad/end card flag
            // in order to better support potential future sequences of ads
            // where there are possibly more than just two ads.
            if index == 0 {
                timeUntilNextAction = timeUntilNextActionDuration(for: videoDuration)
                
                // For video, this is the last ad if there is no end card.
                isLastAd = (endCardType == .none)
            } else {
                timeUntilNextAction = timeUntilNextActionDuration(for: endCardType)
                
                // End cards are always the last ad.
                isLastAd = true
            }
        case .other:
            closeAfter = maxAdExperienceTime
            timeUntilNextAction = adSettings[index].minTimeUntilNextAction;
            
            // For non-VAST ads, there is only ever one ad.
            isLastAd = true
        }
        
        let countdownTime: TimeInterval
        
        // If this is the last ad in the experience, take the longer of
        // the time until next action and the remaining time in the ad
        // experience.
        if isLastAd {
            let clampedElapsedTime = max(elapsedTime, 0)
            // adExperienceTimeRemaining should never be less than 0.
            let adExperienceTimeRemaining = max(closeAfter - clampedElapsedTime, 0)
            countdownTime = max(adExperienceTimeRemaining, timeUntilNextAction)
        } else {
            countdownTime = timeUntilNextAction
        }
        
        return countdownTime
    }
}

// MARK: - Private
internal extension CreativeExperienceSettings {
    /// Returns the `closeAfter` duration in seconds for VAST ads.
    /// - Parameter videoDuration: The duration of the main video.
    /// - Parameter endCard: The type of the end card that will be displayed, or `nil` if there is no end card.
    /// - Returns: The duration in seconds before the user can close out of an ad experience.
    /// - Note: For non-VAST ads, use `maxAdExperienceTime` directly.
    func closeAfterDuration(for videoDuration: TimeInterval, endCardType: EndCardType) -> TimeInterval {
        let endCardDuration: TimeInterval
        
        switch endCardType {
        case .interactive:
            endCardDuration = endCardDurations.interactiveEndCardExperienceDuration
        case .static:
            endCardDuration = endCardDurations.staticEndCardExperienceDuration
        case .none:
            endCardDuration = 0
        }
        
        let clampedVideoDuration = max(videoDuration, 0)
        return min(clampedVideoDuration + endCardDuration, maxAdExperienceTime)
    }
    
    /// Returns the `timeUntilNextAction` duration in seconds for VAST video.
    /// - Parameter videoDuration: The duration of the video.
    /// - Returns: The duration in seconds before the user can perform an action on the main video.
    /// - Note: For non-VAST ads, use `minTimeUntilNextAction` directly.
    func timeUntilNextActionDuration(for videoDuration: TimeInterval) -> TimeInterval {
        guard videoDuration >= 0 else {
            return 0
        }
        
        // Sort the thresholds in descending order, so that videos longer than
        // all skipMins use the longest value.
        let sortedSkipThresholds = vastSkipThresholds.sorted { $0.skipMin > $1.skipMin }
        
        for skipThreshold in sortedSkipThresholds {
            if videoDuration >= skipThreshold.skipMin {
                // Make sure that we don't return a skipAfter that's greater
                // than the video duration.
                return min(skipThreshold.skipAfter, videoDuration)
            }
        }
        
        // Return the video duration if there are no matches.
        return videoDuration
    }
    
    /// Returns the `timeUntilNextAction` duration in seconds for end cards.
    /// - Parameter endCard: The type of the end card that will be displayed, or `nil` if there is no end card.
    /// - Returns: The duration in seconds before the user can perform an action on the end card.
    /// - Note: For non-VAST ads, use `minTimeUntilNextAction` directly.
    func timeUntilNextActionDuration(for endCardType: EndCardType) -> TimeInterval {
        let duration: TimeInterval
        
        switch endCardType {
        case .interactive:
            duration = endCardDurations.minInteractiveEndCardDuration
        case .static:
            duration = endCardDurations.minStaticEndCardDuration
        case .none:
            duration = 0
        }
        
        return duration
    }
}
