//
//  Bool+FromInteger.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

extension Bool {
    /// Initializes a boolean value from an integer with a value of either 1 or 0, or returns `nil` if the
    /// value is anything else.
    /// - Parameter integer: An integer to be converted to a `Bool`.
    init?(integer: Int) {
        switch integer {
        case 0: self = false
        case 1: self = true
        default: return nil
        }
    }
}
