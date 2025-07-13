//
//  ㅇ.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import Foundation
import CoreMotion
import Combine

class AccelerometerManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0 // 50Hz
    private let armMass: Double = 1.2 // kg
    private let accelerationThreshold: Double = 1.5 // G 기준치

    @Published var acceleration: Double = 0.0
    @Published var equivalentMass: Double = 0.0
    @Published var measurementCount: Int = 0
    @Published var maxMass: Double = UserDefaults.standard.double(forKey: "maxMass")

    private var lastMeasurementTime: Date = .distantPast
    private let debounceDuration: TimeInterval = 0.5 // 0.5초 동안 중복 측정 방지

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            print("❌ 가속도계를 사용할 수 없습니다.")
            return
        }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let accelerationData = data else { return }

            let x = accelerationData.acceleration.x
            let y = accelerationData.acceleration.y
            let z = accelerationData.acceleration.z

            let totalG = sqrt(x * x + y * y + z * z)
            self.acceleration = totalG

            let force = self.armMass * totalG * 9.8
            let currentMass = force / 9.8
            self.equivalentMass = currentMass

            if currentMass > self.maxMass {
                self.maxMass = currentMass
                UserDefaults.standard.set(self.maxMass, forKey: "maxMass")
            }

            // ✅ debounce 로직 추가
            let now = Date()
            if totalG > self.accelerationThreshold,
               now.timeIntervalSince(self.lastMeasurementTime) > self.debounceDuration {
                self.measurementCount += 1
                self.lastMeasurementTime = now
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        measurementCount = 0
        maxMass = 0.0
        UserDefaults.standard.set(0.0, forKey: "maxMass")
    }
}

