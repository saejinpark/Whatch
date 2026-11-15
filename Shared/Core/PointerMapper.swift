//
//  PointerMapper.swift
//  Whatch
//

import Foundation

/// Maps where the arm points to a position on the screen.
///
/// The first reading becomes the centre. Sweeping the arm `range` degrees to either side,
/// or up and down, reaches the edges. Positions run from `0` to `1` with `y` growing downwards.
struct PointerMapper: Equatable, Sendable {
    /// Degrees from the centre to an edge.
    var range = 30.0
    /// Flips up and down, for a Watch worn the other way round.
    var invertsVertical = false

    private var centerYaw: Double?
    private var centerRoll: Double?

    init(range: Double = 30, invertsVertical: Bool = false) {
        self.range = range
        self.invertsVertical = invertsVertical
    }

    /// Forgets the centre; the next reading becomes the new one.
    mutating func recenter() {
        centerYaw = nil
        centerRoll = nil
    }

    mutating func point(yaw: Double, roll: Double) -> (x: Double, y: Double) {
        let centerYaw = centerYaw ?? yaw
        let centerRoll = centerRoll ?? roll
        self.centerYaw = centerYaw
        self.centerRoll = centerRoll

        // Yaw grows counter-clockwise, so turning left moves the pointer left.
        let horizontal = HeadingMath.difference(from: centerYaw, to: yaw)
        var vertical = HeadingMath.difference(from: centerRoll, to: roll)
        if invertsVertical { vertical = -vertical }

        let x = 0.5 - horizontal / (2 * range)
        let y = 0.5 - vertical / (2 * range)
        return (min(max(x, 0), 1), min(max(y, 0), 1))
    }
}
