//
//  FlashlightController.swift
//  Whatch
//

import AVFoundation
import Foundation

/// Drives the iPhone torch, either while a button is held or as a toggle.
@MainActor
@Observable
final class FlashlightController {
    private(set) var isOn = false
    var mode: ActivationMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    @ObservationIgnored var onStateChange: ((Bool) -> Void)?

    private static let modeKey = "flashlightMode"

    init() {
        mode = UserDefaults.standard.string(forKey: Self.modeKey)
            .flatMap(ActivationMode.init(rawValue:)) ?? .hold
    }

    /// Sets the torch regardless of `mode`; used for requests coming from the Watch.
    func setOn(_ on: Bool) {
        guard on != isOn else { return }
        isOn = on
        applyTorch(on)
        onStateChange?(on)
    }

    func toggle() {
        setOn(!isOn)
    }

    func pressBegan() {
        if mode == .hold { setOn(true) }
    }

    func pressEnded() {
        if mode == .hold { setOn(false) }
    }

    func tapped() {
        if mode == .toggle { toggle() }
    }

    private func applyTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            Log.features.warning("No torch on this device")
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if on {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
        } catch {
            Log.features.error("Torch update failed: \(error.localizedDescription)")
        }
    }
}
