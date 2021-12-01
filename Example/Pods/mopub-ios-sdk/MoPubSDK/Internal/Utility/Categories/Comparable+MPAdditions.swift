//
//  Comparable+MPAdditions.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

extension Comparable {
    /// Clamp this value to `range`.
    /// - Parameter range: The range to clamp this value to.
    func clamp(to range: ClosedRange<Self>) -> Self {
        return (self < range.lowerBound ? range.lowerBound : (self > range.upperBound ? range.upperBound : self))
    }
}
