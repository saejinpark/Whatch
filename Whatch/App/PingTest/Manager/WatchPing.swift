//
//  WatchPingManager.swift
//  WatchHapticTest
//
//  Created by 박세진 on 7/5/25.
//

import Foundation
import WatchConnectivity
import Combine

class WatchPing: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchPing()

    @Published var isReachable: Bool? = nil
    @Published var lastPingSentAt: Date? = nil
    @Published var lastPongReceivedAt: Date? = nil
    @Published var latency: TimeInterval? = nil

    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 1.0
    private var hasPingStarted = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func ping() {
        if !hasPingStarted {
            isReachable = nil
            hasPingStarted = true
        }

        lastPingSentAt = Date()

        let timestamp = lastPingSentAt!.timeIntervalSince1970
        print("📤 Watch → Phone: ping 전송 (timestamp: \(timestamp))")

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["ping": timestamp], replyHandler: nil, errorHandler: { [weak self] error in
                print("❌ ping 전송 실패: \(error.localizedDescription)")
                self?.timeoutTimer?.invalidate()
                self?.isReachable = false
            })
        } else {
            print("⚠️ Phone 연결 불가 (isReachable == false)")
            isReachable = false
            return
        }

        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            self?.isReachable = false
            print("⏰ Watch: pong 응답 없음 (타임아웃)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let pingTimestamp = message["ping"] as? Double {
            print("📥 Watch: ping 수신됨 → pong 응답 전송")
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["pong": pingTimestamp], replyHandler: nil, errorHandler: { error in
                    print("❌ pong 전송 실패: \(error.localizedDescription)")
                })
            }
        } else if message["pong"] is Double {
            timeoutTimer?.invalidate()
            lastPongReceivedAt = Date()
            if let sent = lastPingSentAt {
                latency = lastPongReceivedAt!.timeIntervalSince(sent)
            }
            isReachable = true
            print("📥 Watch: pong 수신됨, latency: \(latency ?? 0)s")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("⌚️ WatchPing 세션 활성화됨: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}

