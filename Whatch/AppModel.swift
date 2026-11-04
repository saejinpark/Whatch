//
//  AppModel.swift
//  Whatch
//

import Foundation

/// Owns the long-lived services of the iPhone app and routes messages from the Watch to them.
@MainActor
@Observable
final class AppModel {
    let session = ConnectivitySession()
    let battery = BatteryMonitor()
    let heading = HeadingMonitor()
    let flashlight = FlashlightController()
    let haptic = HapticController()
    let ping: PingMonitor

    init() {
        ping = PingMonitor(session: session)
        wire()
    }

    /// Starts the services that report to the Watch continuously.
    func start() {
        battery.start()
        heading.start()
    }

    func stop() {
        battery.stop()
        heading.stop()
    }

    private func wire() {
        session.onMessage = { [weak self] message in
            self?.handle(message)
        }
        session.onReachabilityChange = { [weak self] reachable in
            guard let self, reachable else { return }
            // Bring a freshly connected Watch up to date.
            battery.resendLocalLevel()
            session.send(.flashlight(isOn: flashlight.isOn))
            session.send(.haptic(isOn: haptic.isPlaying))
        }
        battery.onLocalLevelChange = { [weak self] level in
            self?.session.send(.batteryLevel(level))
        }
        heading.onHeadingChange = { [weak self] degrees in
            self?.session.send(.heading(degrees))
        }
        flashlight.onStateChange = { [weak self] isOn in
            self?.session.send(.flashlight(isOn: isOn))
        }
        haptic.onStateChange = { [weak self] isPlaying in
            self?.session.send(.haptic(isOn: isPlaying))
        }
    }

    private func handle(_ message: WatchMessage) {
        switch message {
        case .flashlight(let isOn):
            flashlight.setOn(isOn)
        case .haptic(let isOn):
            haptic.setPlaying(isOn)
        case .heading(let degrees):
            heading.updateRemoteHeading(degrees)
        case .batteryLevel(let level):
            battery.updateRemoteLevel(level)
        case .pong:
            ping.handle(message)
        case .ping:
            break // Answered by the session itself.
        }
    }
}
