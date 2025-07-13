//
//  HapticManager.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import CoreHaptics
import Foundation
import SwiftUI

@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()

    @Published var isPlaying: Bool = false
    @AppStorage("hapticMode") var mode: HapticMode = .pressToVibrate

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("❌ 이 기기는 Core Haptics를 지원하지 않습니다.")
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("❌ Haptic Engine 시작 실패: \(error)")
        }
    }

    func handlePressBegan() {
        if mode == .pressToVibrate {
            turnOn()
        }
    }

    func handlePressEnded() {
        if mode == .pressToVibrate {
            turnOff()
        }
    }

    func handleTap() {
        if mode == .toggle {
            toggle()
        }
    }

    func toggle() {
        isPlaying.toggle()
        isPlaying ? start() : stop()
    }

    func turnOn() {
        if !isPlaying {
            isPlaying = true
            start()
        }
    }

    func turnOff() {
        if isPlaying {
            isPlaying = false
            stop()
        }
    }

    private func start() {
        guard let engine else { return }

        stop() // 👉 중복 실행 방지 위해 먼저 정지

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 30.0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: 0)
            print("🔔 진동 시작")
            WatchSender.shared.sendHapticUpdateRequest(on: true)

            objectWillChange.send()
        } catch {
            print("❌ 진동 패턴 시작 실패: \(error)")
        }
    }

    private func stop() {
        guard let player else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectWillChange.send()
        }

        do {
            try player.stop(atTime: 0)
            self.player = nil
            print("🔕 진동 중지")
            WatchSender.shared.sendHapticUpdateRequest(on: false)
        } catch {
            print("❌ 진동 중지 실패: \(error)")
        }
    }
}

