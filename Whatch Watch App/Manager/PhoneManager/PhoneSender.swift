//
//  IPhoneSender.swift
//  WatchHapticTest
//
//  Created by 박세진 on 7/4/25.
//

import Foundation
import WatchConnectivity

class PhoneSender: ObservableObject {
    static let shared = PhoneSender()

    private(set) var lastRequest: String?
    
    private var pendingAction: (() -> Void)?

    func sendFlashLightRequest(on: Bool) {
        lastRequest = "FlashLightToggle"
        send(["request": "FlashLightToggle:\(on ? "ON" : "OFF")"])
    }
    
    func sendHapticRequest(on: Bool) {
        lastRequest = "HapticToggle"
        send(["request": "HapticToggle:\(on ? "ON" : "OFF")"])
    }
    
    func sendHeadingUpdateRequest(_ heading: Double) {
        send(["anotherTrueHeading": heading])
    }
    
    func sendBatteryLevelUpdate(_ level: Float) {
        let message = ["anotherBatteryLevel": level]
        send(message)
    }
    
    func clearState() {
        lastRequest = nil
        pendingAction = nil
    }

    func sendOKResponse() {
        send(["response": "OK"])
    }
    
    
    func handleResponse(_ response: String) {
        if response == "OK" {
            pendingAction?()
            clearState()
            print("✅ 요청 실행 완료")
        }
    }

    private func send(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⚠️ Phone에 도달할 수 없음")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ 메시지 전송 실패: \(error.localizedDescription)")
        })
    }
}


