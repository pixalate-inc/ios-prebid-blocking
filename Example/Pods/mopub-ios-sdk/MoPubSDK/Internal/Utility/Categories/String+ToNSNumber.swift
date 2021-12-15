//
//  String+ToNSNumber.swift
//
//  Copyright 2018-2021 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

import Foundation

extension String {
    
    /// For SKAdNetwork, convert a `String` to an unsigned 64 bit `NSNumber`
    var unsignedNSNumber: NSNumber? {
        guard let value = UInt64(self) else {
            return nil
        }
        
        return NSNumber(value: value)
    }
    
}
