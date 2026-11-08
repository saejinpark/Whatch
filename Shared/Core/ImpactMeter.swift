//
//  ImpactMeter.swift
//  Whatch
//

import Foundation

/// Turns acceleration readings into "how hard was that swing".
struct ImpactMeter: Equatable, Sendable {
    /// Rough mass of a forearm and hand, used to express force as a weight.
    static let armMass = 1.2 // kg

    /// Current total acceleration in G.
    private(set) var current = 0.0
    /// Strongest acceleration seen, in G.
    private(set) var peak: Double
    /// Number of swings that crossed `threshold`.
    private(set) var count = 0

    let threshold: Double
    let debounce: TimeInterval
    private var lastCountedAt: Date?

    init(peak: Double = 0, threshold: Double = 1.5, debounce: TimeInterval = 0.5) {
        self.peak = peak
        self.threshold = threshold
        self.debounce = debounce
    }

    /// The force on the arm right now, expressed as an equivalent mass in kg.
    var equivalentMass: Double { Self.armMass * current }
    var peakMass: Double { Self.armMass * peak }

    mutating func add(x: Double, y: Double, z: Double, at time: Date) {
        current = (x * x + y * y + z * z).squareRoot()
        peak = max(peak, current)

        guard current > threshold else { return }
        if let lastCountedAt, time.timeIntervalSince(lastCountedAt) <= debounce {
            return
        }
        count += 1
        lastCountedAt = time
    }

    mutating func reset() {
        current = 0
        peak = 0
        count = 0
        lastCountedAt = nil
    }
}
