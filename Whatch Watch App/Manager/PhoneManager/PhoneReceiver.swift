//
//  IPhoneReceiver.swift
//  WatchHapticTest Watch App
//
//  Created by 박세진 on 7/4/25.
//

import Foundation
import WatchConnectivity

// ✅ Watch -> iPhone 메시지 수신 처리
class PhoneReceiver: NSObject, @preconcurrency WCSessionDelegate, ObservableObject {
    static let shared = PhoneReceiver()
    private(set) var lastResponse: String?

    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    @MainActor func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📥 iPhone 수신 메시지:", message)
        
        DispatchQueue.main.async {
            self.lastResponse = message.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        }

        if let request = message["request"] as? String {
            switch request {
            case "FlashLightStatus:ON":
                FlashLightManager.shared.updateState(true)
            case "FlashLightStatus:OFF":
                FlashLightManager.shared.updateState(false)
            case "HapticStatus:ON":
                HapticManager.shared.updateState(true)
            case "HapticStatus:OFF":
                HapticManager.shared.updateState(false)
            default:
                print("왜 안먹는가")
            }
        }
        
        if let heading = message["anotherTrueHeading"] as? Double {
            HeadingMonitorManager.shared.setAnotherTrueHeading(heading)
        }
        
        if let batteryLevel = message["anotherBatteryLevel"] as? Float {
            BatteryStatusManager.shared.setAnotherBatteryLevel(batteryLevel)
        }
        
        if let response = message["response"] as? String, response == "OK" {
            lastResponse = response
            PhoneSender.shared.handleResponse(response)
        }
        
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("📱 Phone session activated: \(activationState.rawValue)")
    }
}


