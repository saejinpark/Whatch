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
    /// Gravity alone along the screen's x and y axes, in G: how the Watch is tilted.
    var gravityX: Double
    var gravityY: Double
    /// Rotation around the vertical axis, in degrees within `-180...180`.
    var yaw: Double
    /// Rotation around the screen's vertical axis, in degrees within `-180...180`.
    var roll: Double
}

/// One consumer's subscription to wrist motion, delivered at 50 Hz on the main actor.
@MainActor
final class MotionFeed {
    private var token: UUID?

    var isAvailable: Bool {
        MotionHub.shared.isAvailable
    }

    func start(handler: @escaping @MainActor (MotionSample) -> Void) {
        stop()
        token = MotionHub.shared.add(handler)
    }

    func stop() {
        if let token {
            MotionHub.shared.remove(token)
        }
        token = nil
    }
}

/// The app's single `CMMotionManager`, shared by every feed.
///
/// Apple recommends one manager per app, and it delivers to one handler; a screen and the
/// controller stream can both need motion at once, so the hub fans each reading out.
@MainActor
final class MotionHub {
    static let shared = MotionHub()

    private let manager = CMMotionManager()
    private var handlers: [UUID: @MainActor (MotionSample) -> Void] = [:]
    private var simulation: Task<Void, Never>?
    private static let interval = 1.0 / 50.0

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        manager.isDeviceMotionAvailable
        #endif
    }

    func add(_ handler: @escaping @MainActor (MotionSample) -> Void) -> UUID {
        let token = UUID()
        handlers[token] = handler
        if handlers.count == 1 {
            startUpdates()
        }
        return token
    }

    func remove(_ token: UUID) {
        handlers[token] = nil
        if handlers.isEmpty {
            stopUpdates()
        }
    }

    private func deliver(_ sample: MotionSample) {
        for handler in handlers.values {
            handler(sample)
        }
    }

    private func startUpdates() {
        #if targetEnvironment(simulator)
        startSimulation()
        #else
        guard manager.isDeviceMotionAvailable else {
            Log.sensors.warning("Device motion is not available")
            return
        }
        manager.deviceMotionUpdateInterval = Self.interval
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let sample = MotionSample(
                x: motion.gravity.x + motion.userAcceleration.x,
                y: motion.gravity.y + motion.userAcceleration.y,
                z: motion.gravity.z + motion.userAcceleration.z,
                gravityX: motion.gravity.x,
                gravityY: motion.gravity.y,
                yaw: motion.attitude.yaw * 180 / .pi,
                roll: motion.attitude.roll * 180 / .pi
            )
            // Updates are delivered on the main queue, as requested above.
            MainActor.assumeIsolated {
                self?.deliver(sample)
            }
        }
        #endif
    }

    private func stopUpdates() {
        simulation?.cancel()
        simulation = nil
        #if !targetEnvironment(simulator)
        manager.stopDeviceMotionUpdates()
        #endif
    }

    /// Simulators have no motion sensors; play a repeating swing and a slow tilt so the screens can be checked.
    private func startSimulation() {
        simulation?.cancel()
        simulation = Task { [weak self] in
            var time = 0.0
            while !Task.isCancelled, let self {
                let phase = time.truncatingRemainder(dividingBy: 3)
                let swing = phase < 0.25 ? 2.6 * sin(phase / 0.25 * .pi) : 0
                let tremor = 0.04 * sin(time * 40) + (phase < 0.6 ? 0.25 * sin(time * 70) : 0)
                var angle = (time * 80).truncatingRemainder(dividingBy: 360)
                if angle > 180 { angle -= 360 }
                self.deliver(MotionSample(x: swing + tremor, y: tremor, z: -1,
                                          gravityX: 0.45 * sin(time * 0.9), gravityY: 0.45 * cos(time * 0.6),
                                          yaw: angle, roll: angle))
                time += Self.interval
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
    }
}
