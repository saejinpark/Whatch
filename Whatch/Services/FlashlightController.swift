//
//  FlashlightController.swift
//  Whatch
//

import AVFoundation
import Foundation

/// How a press-style control behaves: active only while held, or flipped on each tap.
enum ActivationMode: String, CaseIterable, Identifiable {
    case hold
    case toggle

    var id: Self { self }

    var title: String {
        switch self {
        case .hold: "누르는 동안"
        case .toggle: "토글"
        }
    }
}

/// Drives the iPhone torch.
@MainActor
@Observable
final class FlashlightController {
    private(set) var isOn = false
    var mode: ActivationMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }
    /// Torch level in `0.1...1`.
    var brightness: Double {
        didSet {
            UserDefaults.standard.set(brightness, forKey: Self.brightnessKey)
            if isOn { applyTorch(true) }
        }
    }

    @ObservationIgnored var onStateChange: (() -> Void)?

    private static let modeKey = "flashlightMode"
    private static let brightnessKey = "flashlightBrightness"

    init() {
        let defaults = UserDefaults.standard
        mode = defaults.string(forKey: Self.modeKey).flatMap(ActivationMode.init(rawValue:)) ?? .toggle
        let stored = defaults.double(forKey: Self.brightnessKey)
        brightness = stored > 0 ? min(max(stored, TorchLevel.minimumBrightness), 1) : 1
    }

    var hasTorch: Bool {
        AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    }

    /// Whether the hardware reports the torch as lit. Used by the self-test.
    var isTorchActive: Bool {
        AVCaptureDevice.default(for: .video)?.isTorchActive ?? false
    }

    /// Sets the torch regardless of `mode`; also used for requests from the Watch.
    func setOn(_ on: Bool) {
        guard on != isOn else { return }
        // Turning off always sticks; turning on only counts if the torch really came on.
        guard applyTorch(on) || !on else { return }
        isOn = on
        onStateChange?()
    }

    func pressBegan() {
        if mode == .hold { setOn(true) }
    }

    func pressEnded() {
        if mode == .hold { setOn(false) }
    }

    func tapped() {
        if mode == .toggle { setOn(!isOn) }
    }

    @discardableResult
    private func applyTorch(_ on: Bool) -> Bool {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            #if targetEnvironment(simulator)
            return true // Nothing to drive, but keep the UI testable.
            #else
            Log.features.warning("No torch on this device")
            return false
            #endif
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if on {
                switch TorchLevel(brightness: brightness) {
                case .maximum:
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                case .fraction(let level):
                    try device.setTorchModeOn(level: level)
                }
            } else {
                device.torchMode = .off
            }
            return true
        } catch {
            Log.features.error("Torch update failed: \(error.localizedDescription)")
            return false
        }
    }
}
