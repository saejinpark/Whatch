//
//  WatchSender.swift
//  WatchHapticTest
//
//  Created by 박세진 on 7/4/25.
//

import Foundation
import WatchConnectivity

class WatchSender: ObservableObject {
    static let shared = WatchSender()

    private(set) var lastRequest: String?
    
    private var pendingAction: (() -> Void)?
    
    func sendFlashLightUpdateRequest(on: Bool) {
        send(["request": "FlashLightStatus:\(on ? "ON" : "OFF")"])
    }
    
    func sendHapticUpdateRequest(on: Bool) {
        send(["request": "HapticStatus:\(on ? "ON" : "OFF")"])
    }
    
    func sendHeadingUpdateRequest(_ heading: Double) {
        send(["anotherTrueHeading": heading])
    }
    
    func sendBatteryLevelUpdate(_ level: Float) {
        let message = ["anotherBatteryLevel": level]
        send(message)
    }

    func handleResponse(_ response: String) {
        if response == "OK" {
            pendingAction?()
            clearState()
            print("✅ 요청 실행 완료")
        }
    }

    func clearState() {
        lastRequest = nil
        pendingAction = nil
    }


    private func send(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⚠️ Watch에 도달할 수 없음")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ 메시지 전송 실패: \(error.localizedDescription)")
        })
    }
}




