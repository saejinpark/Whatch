//
//  RollTrackerYManager.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import Foundation
import CoreMotion

class RollTrackerYManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0

    @Published var totalRotationDegrees: Double = 0
    @Published var isPaused: Bool = false
    private var previousRoll: Double?

    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let motion = data else { return }
            guard !self.isPaused else { return }

            let roll = motion.attitude.roll * 180 / .pi // ✅ Z축 회전 (손목을 좌우로 비트는 동작)

            if let previous = self.previousRoll {
                var delta = roll - previous

                // -180 ~ 180 넘어가는 부분 보정
                if delta > 180 {
                    delta -= 360
                } else if delta < -180 {
                    delta += 360
                }

                self.totalRotationDegrees += delta
            }

            self.previousRoll = roll
        }
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }

    func reset() {
        totalRotationDegrees = 0
        previousRoll = nil
    }

    func togglePause() {
        isPaused.toggle()
    }

}
