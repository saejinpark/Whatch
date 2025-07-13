//
//  BetteryStatusManagere.swift
//  Whatch
//
//  Created by 박세진 on 7/13/25.
//
import Foundation
import SwiftUI
import WatchKit

@MainActor
class BatteryStatusManager: ObservableObject {
    static let shared = BatteryStatusManager()
    
    @Published var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel
    @Published var anotherBatteryLevel: Float = -1

    private var lastSentLevel: Float = -1
    private let sendThreshold: Float = 0.01
    private var timer: Timer?

    private init() {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
    }

    func setAnotherBatteryLevel(_ level: Float) {
        anotherBatteryLevel = level
    }

    func startMonitoring() {
        stopMonitoring()
        updateBatteryLevel()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateBatteryLevel()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateBatteryLevel() {
        let current = WKInterfaceDevice.current().batteryLevel
        batteryLevel = current >= 0 ? current : 0.0
        print("me: \(batteryLevel), another: \(anotherBatteryLevel)")

        PhoneSender.shared.sendBatteryLevelUpdate(current)
        print("📤 배터리 전송: \(Int(current * 100))%")

        objectWillChange.send()
    }
}


