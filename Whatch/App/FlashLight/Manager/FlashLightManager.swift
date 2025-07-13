//
//  FlashLightManager.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import AVFoundation
import SwiftUI

@MainActor
class FlashLightManager: ObservableObject {
    static let shared = FlashLightManager()

    @Published var isOn: Bool = false
    @AppStorage("flashMode") var mode: FlashMode = .pressToShine

    private init() {}

    func handlePressBegan() {
        if mode == .pressToShine {
            turnOn()
        }
    }

    func handlePressEnded() {
        if mode == .pressToShine {
            turnOff()
        }
    }

    func handleTap() {
        if mode == .toggle {
            toggleFlashlight()
        }
    }

    func toggleFlashlight() {
        isOn.toggle()
        updateTorch(isOn)
    }

    func turnOn() {
        isOn = true
        updateTorch(true)
    }

    func turnOff() {
        isOn = false
        updateTorch(false)
    }

    private func updateTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        WatchSender.shared.sendFlashLightUpdateRequest(on: on)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectWillChange.send()
        }

        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("🔦 플래시 제어 실패: \(error)")
        }
        
    }
}
