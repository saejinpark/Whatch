//
//  RollTrackerXManager.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

import Foundation
import CoreMotion

class RollTrackerXManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0

    @Published var totalRotationDegrees: Double = 0
    @Published var isPaused: Bool = false
    private var previousYaw: Double?

    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let motion = data else { return }
            guard !self.isPaused else { return }

            let yaw = motion.attitude.yaw * 180 / .pi // 라디안 → 도

            if let previous = self.previousYaw {
                var delta = yaw - previous

                // -180 ~ 180 넘어가는 부분 보정
                if delta > 180 {
                    delta -= 360
                } else if delta < -180 {
                    delta += 360
                }

                self.totalRotationDegrees += delta
            }

            self.previousYaw = yaw
        }
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }

    func reset() {
        totalRotationDegrees = 0
        previousYaw = nil
    }

    func togglePause() {
        isPaused.toggle()
    }
}
