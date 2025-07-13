//
//  BetteryStatusManagere.swift
//  Whatch
//
//  Created by 박세진 on 7/13/25.
//
import Foundation
import SwiftUI
import UIKit

@MainActor
class BatteryStatusManager: ObservableObject {
    static let shared = BatteryStatusManager()

    @Published var batteryLevel: Float = UIDevice.current.batteryLevel
    @Published var anotherBatteryLevel: Float = -1  // 외부 기기 배터리 수준 (% 기준)

    private var timer: Timer?

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    func setAnotherBatteryLevel(_ level: Float) {
        anotherBatteryLevel = level
        objectWillChange.send()
        print("📡 외부 배터리 레벨 설정됨: \(Int(level * 100))%")
    }

    func startMonitoring() {
        stopMonitoring()
        updateBatteryLevel()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        let current = UIDevice.current.batteryLevel
        batteryLevel = current >= 0 ? current : 0.0
        
        print("me: \(batteryLevel), another: \(anotherBatteryLevel)")
        
        WatchSender.shared.sendBatteryLevelUpdate(current)
        print("📤 배터리 전송: \(Int(current * 100))%")

        objectWillChange.send()
    }
}



