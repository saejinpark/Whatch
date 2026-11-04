//
//  VibrationDetector.swift
//  Whatch Watch App
//

import CoreMotion
import Foundation

/// Keeps the last second of frame-to-frame acceleration changes, which spike when the wrist shakes.
@MainActor
@Observable
final class VibrationDetector {
    private(set) var samples: [Double] = []

    @ObservationIgnored private let motionManager = CMMotionManager()
    @ObservationIgnored private var previousAcceleration: CMAcceleration?

    private static let updateInterval = 1.0 / 50.0
    private static let sampleLimit = 50

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            Log.sensors.warning("Accelerometer is not available")
            return
        }
        motionManager.accelerometerUpdateInterval = Self.updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let acceleration = data?.acceleration else { return }
            MainActor.assumeIsolated {
                self?.record(acceleration)
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        samples = []
        previousAcceleration = nil
    }

    private func record(_ acceleration: CMAcceleration) {
        defer { previousAcceleration = acceleration }
        guard let previous = previousAcceleration else { return }

        let dx = acceleration.x - previous.x
        let dy = acceleration.y - previous.y
        let dz = acceleration.z - previous.z
        samples.append((dx * dx + dy * dy + dz * dz).squareRoot())
        if samples.count > Self.sampleLimit {
            samples.removeFirst()
        }
    }
}
