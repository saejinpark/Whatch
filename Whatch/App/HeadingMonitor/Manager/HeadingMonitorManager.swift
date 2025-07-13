//
//  HeadingMonitorManager.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class HeadingMonitorManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    static let shared = HeadingMonitorManager()
    
    @Published var heading: CLHeading?
    @Published var anotherTrueHeading: CLLocationDirection = 0.0  // 진북 기준 외부 값

    private let locationManager = CLLocationManager()
    private var lastSentHeading: CLLocationDirection = -1
    private let sendThreshold: CLLocationDirection = 1.0  // 5도 이상 차이날 때만 전송

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.headingOrientation = .portrait
        locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        guard CLLocationManager.headingAvailable() else {
            print("❌ Heading 정보 사용 불가")
            return
        }
        locationManager.startUpdatingHeading()
    }

    func stopMonitoring() {
        locationManager.stopUpdatingHeading()
    }

    // ✅ 외부에서 다른 기기의 heading 값을 진북 기준으로 설정
    func setAnotherTrueHeading(_ heading: CLLocationDirection) {
        self.anotherTrueHeading = heading
    }

    // ✅ 기기 heading 업데이트 감지
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
        
        let trueHeading = newHeading.trueHeading
        
        // 변화가 있으면 메시지 전송
        if abs(trueHeading - lastSentHeading) >= sendThreshold {
            lastSentHeading = trueHeading
            // 예시: 다른 기기로 heading 값 전송
            WatchSender.shared.sendHeadingUpdateRequest(trueHeading)
        }
    }
}
