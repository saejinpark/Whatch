//
//  VibrationAnalyzer.swift
//  Whatch
//

import Foundation

/// Measures shaking as the change in acceleration between consecutive readings.
struct VibrationAnalyzer: Equatable, Sendable {
    enum Level: Equatable, Sendable {
        case calm
        case moving
        case intense

        var title: String {
            switch self {
            case .calm: "잔잔함"
            case .moving: "흔들림"
            case .intense: "격렬함"
            }
        }
    }

    /// Recent change magnitudes in G, oldest first.
    private(set) var samples: [Double] = []
    private(set) var peak = 0.0

    let sampleLimit: Int
    private var previous: (x: Double, y: Double, z: Double)?

    init(sampleLimit: Int = 60) {
        self.sampleLimit = sampleLimit
    }

    /// Average of the last few samples, so the reading does not flicker.
    var intensity: Double {
        let recent = samples.suffix(10)
        return recent.isEmpty ? 0 : recent.reduce(0, +) / Double(recent.count)
    }

    var level: Level {
        switch intensity {
        case ..<0.05: .calm
        case ..<0.3: .moving
        default: .intense
        }
    }

    mutating func add(x: Double, y: Double, z: Double) {
        defer { previous = (x, y, z) }
        guard let previous else { return }

        let dx = x - previous.x
        let dy = y - previous.y
        let dz = z - previous.z
        let delta = (dx * dx + dy * dy + dz * dz).squareRoot()

        samples.append(delta)
        if samples.count > sampleLimit {
            samples.removeFirst(samples.count - sampleLimit)
        }
        peak = max(peak, delta)
    }

    mutating func reset() {
        samples = []
        peak = 0
        previous = nil
    }

    static func == (lhs: VibrationAnalyzer, rhs: VibrationAnalyzer) -> Bool {
        lhs.samples == rhs.samples && lhs.peak == rhs.peak && lhs.sampleLimit == rhs.sampleLimit
    }
}
