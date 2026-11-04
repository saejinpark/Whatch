//
//  HapticController.swift
//  Whatch
//

import CoreHaptics
import Foundation

/// Plays a continuous vibration, either while a button is held or as a toggle.
@MainActor
@Observable
final class HapticController {
    private(set) var isPlaying = false
    var mode: ActivationMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    @ObservationIgnored var onStateChange: ((Bool) -> Void)?

    @ObservationIgnored private var engine: CHHapticEngine?
    @ObservationIgnored private var player: CHHapticAdvancedPatternPlayer?

    private static let modeKey = "hapticMode"
    private static let patternDuration: TimeInterval = 30

    init() {
        mode = UserDefaults.standard.string(forKey: Self.modeKey)
            .flatMap(ActivationMode.init(rawValue:)) ?? .hold
        engine = Self.makeEngine()
    }

    /// Starts or stops regardless of `mode`; used for requests coming from the Watch.
    func setPlaying(_ playing: Bool) {
        guard playing != isPlaying else { return }
        isPlaying = playing
        playing ? startPattern() : stopPattern()
        onStateChange?(playing)
    }

    func toggle() {
        setPlaying(!isPlaying)
    }

    func pressBegan() {
        if mode == .hold { setPlaying(true) }
    }

    func pressEnded() {
        if mode == .hold { setPlaying(false) }
    }

    func tapped() {
        if mode == .toggle { toggle() }
    }

    private static func makeEngine() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            Log.features.warning("Core Haptics is not supported on this device")
            return nil
        }
        do {
            return try CHHapticEngine()
        } catch {
            Log.features.error("Haptic engine creation failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func startPattern() {
        guard let engine else { return }
        stopPattern()

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
            ],
            relativeTime: 0,
            duration: Self.patternDuration
        )
        do {
            // The engine stops on its own in the background; starting a running engine is harmless.
            try engine.start()
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            Log.features.error("Haptic pattern start failed: \(error.localizedDescription)")
        }
    }

    private func stopPattern() {
        guard let player else { return }
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch {
            Log.features.error("Haptic pattern stop failed: \(error.localizedDescription)")
        }
        self.player = nil
    }
}
