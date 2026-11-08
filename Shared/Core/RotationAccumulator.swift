//
//  RotationAccumulator.swift
//  Whatch
//

import Foundation

/// Adds up how far an angle has travelled, across the ±180° wrap-around.
struct RotationAccumulator: Equatable, Sendable {
    private(set) var totalDegrees = 0.0
    /// While paused, movement is ignored and does not show up after resuming.
    var isPaused = false

    private var previous: Double?

    var turns: Double {
        totalDegrees / 360
    }

    /// Feeds the next attitude angle, in degrees within `-180...180`.
    mutating func add(angle: Double) {
        defer { previous = angle }
        guard !isPaused, let previous else { return }

        var delta = angle - previous
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        totalDegrees += delta
    }

    mutating func reset() {
        totalDegrees = 0
        previous = nil
    }
}
