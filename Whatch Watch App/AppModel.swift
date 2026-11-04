//
//  AppModel.swift
//  Whatch Watch App
//

import Foundation

/// Owns the long-lived services of the Watch app and routes messages from the iPhone to them.
@MainActor
@Observable
final class AppModel {
    let session = ConnectivitySession()
    let battery = BatteryMonitor()
    let heading = HeadingMonitor()
    let ping: PingMonitor
    /// Mirrors the iPhone flashlight; `toggle()` asks the phone to flip it.
    let flashlight: RemoteSwitch
    /// Mirrors the iPhone haptic engine; `toggle()` asks the phone to flip it.
    let haptic: RemoteSwitch

    init() {
        ping = PingMonitor(session: session)
        flashlight = RemoteSwitch(session: session) { .flashlight(isOn: $0) }
        haptic = RemoteSwitch(session: session) { .haptic(isOn: $0) }
        wire()
    }

    /// Starts the services that report to the iPhone continuously.
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
            if reachable { self?.battery.resendLocalLevel() }
        }
        battery.onLocalLevelChange = { [weak self] level in
            self?.session.send(.batteryLevel(level))
        }
        heading.onHeadingChange = { [weak self] degrees in
            self?.session.send(.heading(degrees))
        }
    }

    private func handle(_ message: WatchMessage) {
        switch message {
        case .flashlight(let isOn):
            flashlight.apply(isOn: isOn)
        case .haptic(let isOn):
            haptic.apply(isOn: isOn)
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
