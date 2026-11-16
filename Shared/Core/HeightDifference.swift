//
//  HeightDifference.swift
//  Whatch
//

import Foundation

/// How much higher the other device is than this one, from the two barometers.
///
/// Two barometers rarely agree exactly, so hold the devices side by side and `calibrate`
/// first. After that a change of one centimetre is about 0.0012 hPa, near the sensors'
/// noise, so the result is smoothed and good to roughly ten or twenty centimetres.
struct HeightDifference: Equatable, Sendable {
    private(set) var localPressure: Double?
    private(set) var remotePressure: Double?
    /// What the raw difference read when the devices were side by side.
    private(set) var offset = 0.0
    /// Share of each new reading that is taken; lower is smoother.
    let smoothing: Double

    init(smoothing: Double = 0.3) {
        self.smoothing = smoothing
    }

    /// Altitude in metres for a pressure in kPa, in the standard atmosphere.
    static func altitude(forPressure kPa: Double) -> Double {
        44_330.77 * (1 - pow(kPa / 101.325, 0.190263))
    }

    mutating func updateLocal(_ kPa: Double) {
        localPressure = smoothed(localPressure, kPa)
    }

    mutating func updateRemote(_ kPa: Double) {
        remotePressure = smoothed(remotePressure, kPa)
    }

    /// The other device stopped reporting.
    mutating func clearRemote() {
        remotePressure = nil
    }

    /// Height of the other device above this one in metres, before calibration.
    var raw: Double? {
        guard let localPressure, let remotePressure else { return nil }
        return Self.altitude(forPressure: remotePressure) - Self.altitude(forPressure: localPressure)
    }

    /// Height of the other device above this one in metres. Negative when it is lower.
    var meters: Double? {
        raw.map { $0 - offset }
    }

    /// Declares the devices level right now.
    mutating func calibrate() {
        if let raw { offset = raw }
    }

    private func smoothed(_ previous: Double?, _ kPa: Double) -> Double? {
        // Pressures outside anything found on Earth's surface are sensor glitches.
        guard kPa.isFinite, kPa > 30, kPa < 120 else { return previous }
        guard let previous else { return kPa }
        return previous + (kPa - previous) * smoothing
    }
}

/// Short distances as text.
enum DistanceFormat {
    /// "38 cm" below a metre, "1.24 m" from there on. The sign is dropped.
    static func text(meters: Double) -> String {
        let distance = abs(meters)
        if distance < 0.995 {
            return "\(Int((distance * 100).rounded())) cm"
        }
        return String(format: "%.2f m", distance)
    }

    /// A person's height: always whole centimetres, "172 cm".
    static func height(meters: Double) -> String {
        "\(Int((abs(meters) * 100).rounded())) cm"
    }
}
