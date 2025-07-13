//
//  VibrationDetectorManager.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

import Foundation
import CoreMotion

class VibrationDetectorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0 // 50Hz

    @Published var vibrationDeltas: [Double] = []
    private var previousAcceleration: CMAcceleration?

    func start() {
        guard motionManager.isAccelerometerAvailable else {
            print("❌ 가속도계를 사용할 수 없습니다.")
            return
        }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let acceleration = data?.acceleration else { return }

            if let prev = self.previousAcceleration {
                let dx = acceleration.x - prev.x
                let dy = acceleration.y - prev.y
                let dz = acceleration.z - prev.z
                let delta = sqrt(dx*dx + dy*dy + dz*dz)

                DispatchQueue.main.async {
                    self.vibrationDeltas.append(delta)
                    if self.vibrationDeltas.count > 50 {
                        self.vibrationDeltas.removeFirst()
                    }
                }
            }

            self.previousAcceleration = acceleration
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        vibrationDeltas = []
        previousAcceleration = nil
    }
}

