import Foundation
import WatchConnectivity

class WatchReceiver: NSObject, @preconcurrency WCSessionDelegate, ObservableObject {
    static let shared = WatchReceiver()
    let sender = WatchSender.shared

    private(set) var lastResponse: String?

    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // 메시지 수신 처리
    @MainActor func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📥 수신된 메시지:", message)

        // 1️⃣ 응답 메시지 (예: "response": "OK")
        if let request = message["request"] as? String {
            switch request {
                case "FlashLightToggle:ON":
                    FlashLightManager.shared.turnOn()
                case "FlashLightToggle:OFF":
                    FlashLightManager.shared.turnOff()
                case "HapticToggle:ON":
                    HapticManager.shared.turnOn()
                case "HapticToggle:OFF":
                    HapticManager.shared.turnOff()
                default:
                    print("fail")
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
            WatchSender.shared.handleResponse(response)
        }
    }

    // 세션 상태 관련 필수 메서드
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("⌚️ Watch session activated: \(activationState.rawValue)")
    }
    
}
