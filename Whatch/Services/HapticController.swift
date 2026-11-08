//
//  HapticController.swift
//  Whatch
//

import CoreHaptics
import Foundation

/// Plays a continuous vibration on the iPhone.
@MainActor
@Observable
final class HapticController {
    private(set) var isPlaying = false
    var mode: ActivationMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }
    /// Vibration strength in `0.2...1`.
    var intensity: Double {
        didSet {
            UserDefaults.standard.set(intensity, forKey: Self.intensityKey)
            applyIntensity()
        }
    }

    @ObservationIgnored var onStateChange: (() -> Void)?

    @ObservationIgnored private var engine: CHHapticEngine?
    @ObservationIgnored private var player: CHHapticAdvancedPatternPlayer?

    private static let modeKey = "hapticMode"
    private static let intensityKey = "hapticIntensity"

    init() {
        let defaults = UserDefaults.standard
        mode = defaults.string(forKey: Self.modeKey).flatMap(ActivationMode.init(rawValue:)) ?? .toggle
        let stored = defaults.double(forKey: Self.intensityKey)
        intensity = stored > 0 ? min(max(stored, 0.2), 1) : 1
    }

    var isSupported: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #endif
    }

    /// Starts or stops regardless of `mode`; also used for requests from the Watch.
    func setPlaying(_ playing: Bool) {
        guard playing != isPlaying else { return }
        if playing {
            guard startPattern() else { return }
        } else {
            stopPattern()
        }
        isPlaying = playing
        onStateChange?()
    }

    func pressBegan() {
        if mode == .hold { setPlaying(true) }
    }

    func pressEnded() {
        if mode == .hold { setPlaying(false) }
    }

    func tapped() {
        if mode == .toggle { setPlaying(!isPlaying) }
    }

    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        // The system stops the engine when the app leaves the screen or audio is interrupted.
        engine.stoppedHandler = { [weak self] _ in
            Task { @MainActor in
                self?.player = nil
                self?.setPlaying(false)
            }
        }
        engine.resetHandler = { [weak self] in
            Task { @MainActor in
                self?.player = nil
                self?.setPlaying(false)
            }
        }
        return engine
    }

    private func startPattern() -> Bool {
        #if targetEnvironment(simulator)
        return true // No haptic hardware, but keep the UI testable.
        #else
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            Log.features.warning("Core Haptics is not supported on this device")
            return false
        }
        do {
            let engine = try engine ?? makeEngine()
            self.engine = engine
            try engine.start()

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                ],
                relativeTime: 0,
                duration: 10
            )
            let player = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
            player.loopEnabled = true
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
            applyIntensity()
            return true
        } catch {
            Log.features.error("Haptic start failed: \(error.localizedDescription)")
            return false
        }
        #endif
    }

    private func stopPattern() {
        guard let player else { return }
        self.player = nil
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch {
            Log.features.error("Haptic stop failed: \(error.localizedDescription)")
        }
    }

    private func applyIntensity() {
        guard let player else { return }
        let parameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                 value: Float(intensity), relativeTime: 0)
        do {
            try player.sendParameters([parameter], atTime: CHHapticTimeImmediate)
        } catch {
            Log.features.error("Haptic intensity update failed: \(error.localizedDescription)")
        }
    }
}
