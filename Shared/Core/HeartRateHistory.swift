//
//  HeartRateHistory.swift
//  Whatch
//

import Foundation

/// Recent heart rate readings and how they compare with where they started.
struct HeartRateHistory: Equatable, Sendable {
    /// Recent readings in beats per minute, oldest first.
    private(set) var samples: [Double] = []
    /// The average of the first few readings, to compare later ones against.
    private(set) var baseline: Double?

    let limit: Int
    let baselineCount: Int
    private var baselineSum = 0.0
    private var baselineSamples = 0

    init(limit: Int = 120, baselineCount: Int = 5) {
        self.limit = limit
        self.baselineCount = baselineCount
    }

    var current: Double? { samples.last }
    var minimum: Double? { samples.min() }
    var maximum: Double? { samples.max() }
    var average: Double? {
        samples.isEmpty ? nil : samples.reduce(0, +) / Double(samples.count)
    }

    /// How far the current reading is above the baseline, once there is one.
    var delta: Double? {
        guard let current, let baseline else { return nil }
        return current - baseline
    }

    /// Adds a reading. Values no heart produces are ignored.
    mutating func add(_ bpm: Double) {
        guard bpm.isFinite, bpm >= 20, bpm <= 250 else { return }
        samples.append(bpm)
        if samples.count > limit {
            samples.removeFirst(samples.count - limit)
        }
        if baselineSamples < baselineCount {
            baselineSum += bpm
            baselineSamples += 1
            if baselineSamples == baselineCount {
                baseline = baselineSum / Double(baselineCount)
            }
        }
    }

    mutating func reset() {
        self = HeartRateHistory(limit: limit, baselineCount: baselineCount)
    }
}
