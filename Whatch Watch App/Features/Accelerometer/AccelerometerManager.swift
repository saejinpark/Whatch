//
//  AccelerometerManager.swift
//  Whatch Watch App
//

import CoreMotion
import Foundation

/// Reads total acceleration at 50 Hz and turns it into "how much weight is on the arm".
@MainActor
@Observable
final class AccelerometerManager {
    /// Current total acceleration in G.
    private(set) var acceleration = 0.0
    /// Force on the arm right now, expressed as an equivalent mass in kg.
    private(set) var equivalentMass = 0.0
    /// Number of swings that exceeded `accelerationThreshold`.
    private(set) var measurementCount = 0
    /// Highest equivalent mass ever recorded; survives app restarts.
    private(set) var maxMass: Double {
        didSet { UserDefaults.standard.set(maxMass, forKey: Self.maxMassKey) }
    }

    @ObservationIgnored private let motionManager = CMMotionManager()
    @ObservationIgnored private var lastCountedAt = Date.distantPast

    private static let maxMassKey = "maxMass"
    private static let updateInterval = 1.0 / 50.0
    private static let armMass = 1.2 // kg
    private static let accelerationThreshold = 1.5 // G
    private static let debounceInterval: TimeInterval = 0.5

    init() {
        maxMass = UserDefaults.standard.double(forKey: Self.maxMassKey)
    }

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            Log.sensors.warning("Accelerometer is not available")
            return
        }
        motionManager.accelerometerUpdateInterval = Self.updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let a = data?.acceleration else { return }
            let totalG = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
            MainActor.assumeIsolated {
                self?.record(totalG: totalG)
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        measurementCount = 0
        maxMass = 0
    }

    private func record(totalG: Double) {
        acceleration = totalG
        equivalentMass = Self.armMass * totalG
        maxMass = max(maxMass, equivalentMass)

        let now = Date()
        if totalG > Self.accelerationThreshold,
           now.timeIntervalSince(lastCountedAt) > Self.debounceInterval {
            measurementCount += 1
            lastCountedAt = now
        }
    }
}
