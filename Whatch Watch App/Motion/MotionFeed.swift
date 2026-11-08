//
//  MotionFeed.swift
//  Whatch Watch App
//

import CoreMotion
import Foundation

/// One reading of how the wrist is moving.
struct MotionSample: Sendable {
    /// Total acceleration including gravity, in G.
    var x: Double
    var y: Double
    var z: Double
    /// Rotation around the vertical axis, in degrees within `-180...180`.
    var yaw: Double
    /// Rotation around the forearm, in degrees within `-180...180`.
    var roll: Double
}

/// Delivers wrist motion at 50 Hz on the main actor.
///
/// Apple recommends a single `CMMotionManager` per app, so every feature reads through here.
@MainActor
final class MotionFeed {
    private static let manager = CMMotionManager()
    private static let interval = 1.0 / 50.0

    private var simulation: Task<Void, Never>?

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        Self.manager.isDeviceMotionAvailable
        #endif
    }

    func start(handler: @escaping @MainActor (MotionSample) -> Void) {
        #if targetEnvironment(simulator)
        startSimulation(handler: handler)
        #else
        let manager = Self.manager
        guard manager.isDeviceMotionAvailable else {
            Log.sensors.warning("Device motion is not available")
            return
        }
        manager.deviceMotionUpdateInterval = Self.interval
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let sample = MotionSample(
                x: motion.gravity.x + motion.userAcceleration.x,
                y: motion.gravity.y + motion.userAcceleration.y,
                z: motion.gravity.z + motion.userAcceleration.z,
                yaw: motion.attitude.yaw * 180 / .pi,
                roll: motion.attitude.roll * 180 / .pi
            )
            // Updates are delivered on the main queue, as requested above.
            MainActor.assumeIsolated {
                handler(sample)
            }
        }
        #endif
    }

    func stop() {
        simulation?.cancel()
        simulation = nil
        #if !targetEnvironment(simulator)
        Self.manager.stopDeviceMotionUpdates()
        #endif
    }

    /// Simulators have no motion sensors; play a repeating swing so the screens can be checked.
    private func startSimulation(handler: @escaping @MainActor (MotionSample) -> Void) {
        simulation?.cancel()
        simulation = Task {
            var time = 0.0
            while !Task.isCancelled {
                let phase = time.truncatingRemainder(dividingBy: 3)
                let swing = phase < 0.25 ? 2.6 * sin(phase / 0.25 * .pi) : 0
                let tremor = 0.04 * sin(time * 40) + (phase < 0.6 ? 0.25 * sin(time * 70) : 0)
                var angle = (time * 80).truncatingRemainder(dividingBy: 360)
                if angle > 180 { angle -= 360 }
                handler(MotionSample(x: swing + tremor, y: tremor, z: -1, yaw: angle, roll: angle))
                time += Self.interval
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
    }
}
