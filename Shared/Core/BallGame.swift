//
//  BallGame.swift
//  Whatch
//

import Foundation

/// A ball rolling on a unit square, steered by tilt. Roll it onto the target to score.
///
/// Coordinates run from `0` to `1`, with `y` growing downwards like the screen.
struct BallGame: Equatable, Sendable {
    static let ballRadius = 0.045
    static let targetRadius = 0.06
    static let duration = 30.0
    /// Acceleration per G of tilt, in field widths per second squared.
    static let acceleration = 2.2

    private(set) var x = 0.5
    private(set) var y = 0.5
    private(set) var velocityX = 0.0
    private(set) var velocityY = 0.0
    private(set) var targetX = 0.75
    private(set) var targetY = 0.25
    private(set) var score = 0
    private(set) var timeRemaining = 0.0
    private var seed: UInt64

    init(seed: UInt64 = 0x5EED) {
        self.seed = seed
    }

    var isRunning: Bool {
        timeRemaining > 0
    }

    mutating func start() {
        x = 0.5
        y = 0.5
        velocityX = 0
        velocityY = 0
        score = 0
        timeRemaining = Self.duration
        placeTarget()
    }

    /// Advances the game. `tiltX` rolls the ball right, `tiltY` rolls it down, both in G.
    mutating func step(dt: Double, tiltX: Double, tiltY: Double) {
        guard isRunning, dt > 0 else { return }
        let dt = min(dt, 0.1)

        velocityX += min(max(tiltX, -1), 1) * Self.acceleration * dt
        velocityY += min(max(tiltY, -1), 1) * Self.acceleration * dt
        // Rolling friction: the ball keeps a quarter of its speed after a second with no tilt.
        let friction = pow(0.25, dt)
        velocityX *= friction
        velocityY *= friction
        x += velocityX * dt
        y += velocityY * dt

        let low = Self.ballRadius, high = 1 - Self.ballRadius
        if x < low { x = low; velocityX = -velocityX * 0.45 }
        if x > high { x = high; velocityX = -velocityX * 0.45 }
        if y < low { y = low; velocityY = -velocityY * 0.45 }
        if y > high { y = high; velocityY = -velocityY * 0.45 }

        if distanceToTarget < Self.ballRadius + Self.targetRadius {
            score += 1
            placeTarget()
        }
        timeRemaining = max(timeRemaining - dt, 0)
    }

    private var distanceToTarget: Double {
        ((x - targetX) * (x - targetX) + (y - targetY) * (y - targetY)).squareRoot()
    }

    /// Puts the target somewhere new, away from the ball.
    private mutating func placeTarget() {
        let margin = Self.targetRadius + 0.02
        for _ in 0..<24 {
            targetX = margin + nextRandom() * (1 - 2 * margin)
            targetY = margin + nextRandom() * (1 - 2 * margin)
            if distanceToTarget > 0.3 { return }
        }
    }

    /// A small deterministic generator, so games can be replayed in tests.
    private mutating func nextRandom() -> Double {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(seed >> 11) / Double(1 << 53)
    }
}
