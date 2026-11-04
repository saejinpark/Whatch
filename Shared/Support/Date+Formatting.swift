//
//  Date+Formatting.swift
//  Whatch
//

import Foundation

extension Date {
    /// `HH:mm:ss.SSS`, used to show when pings were sent and answered.
    var preciseTimeString: String {
        formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .second(.twoDigits)
                .secondFraction(.fractional(3))
        )
    }
}
