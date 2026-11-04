//
//  RotationTracker.swift
//  Whatch Watch App
//

import CoreMotion
import Foundation

/// Which attitude angle a `RotationTracker` accumulates.
enum RotationAxis {
    /// Rotation around the vertical axis: turning the wrist left and right.
    case yaw
    /// Rotation around the forearm: twisting the wrist.
    case roll

    fileprivate func degrees(of attitude: CMAttitude) -> Double {
        switch self {
        case .yaw: attitude.yaw * 180 / .pi
        case .roll: attitude.roll * 180 / .pi
        }
    }
}

/// Accumulates how far the wrist has rotated around one axis, in degrees.
@MainActor
@Observable
final class RotationTracker {
    let axis: RotationAxis
    private(set) var totalDegrees = 0.0
    var isPaused = false

    @ObservationIgnored private let motionManager = CMMotionManager()
    @ObservationIgnored private var previousDegrees: Double?

    private static let updateInterval = 1.0 / 50.0

    init(axis: RotationAxis) {
        self.axis = axis
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            Log.sensors.warning("Device motion is not available")
            return
        }
        motionManager.deviceMotionUpdateInterval = Self.updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let degrees = axis.degrees(of: motion.attitude)
            MainActor.assumeIsolated {
                self.record(degrees)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func reset() {
        totalDegrees = 0
        previousDegrees = nil
    }

    func togglePause() {
        isPaused.toggle()
    }

    private func record(_ degrees: Double) {
        defer { previousDegrees = degrees }
        guard !isPaused, let previous = previousDegrees else { return }

        // Attitude angles wrap at ±180°; take the short way round.
        var delta = degrees - previous
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        totalDegrees += delta
    }
}
