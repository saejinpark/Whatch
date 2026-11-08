//
//  HeadingMath.swift
//  Whatch
//

import Foundation

/// Compass arithmetic in degrees.
enum HeadingMath {
    /// Wraps any angle into `0..<360`.
    static func normalized(_ degrees: Double) -> Double {
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    /// The shortest turn from `from` to `to`, in `-180...180`. Positive is clockwise.
    static func difference(from: Double, to: Double) -> Double {
        let delta = normalized(to - from)
        return delta > 180 ? delta - 360 : delta
    }

    /// The nearest of the eight compass points.
    static func cardinal(for degrees: Double) -> String {
        let names = ["북", "북동", "동", "남동", "남", "남서", "서", "북서"]
        let index = Int((normalized(degrees) / 45).rounded()) % names.count
        return names[index]
    }
}
