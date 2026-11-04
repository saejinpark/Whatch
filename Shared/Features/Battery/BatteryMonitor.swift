//
//  BatteryMonitor.swift
//  Whatch
//

import Foundation

/// Polls this device's battery level once a second and reports changes through
/// `onLocalLevelChange` so they can be forwarded to the counterpart device.
@MainActor
@Observable
final class BatteryMonitor {
    /// This device's level in `0...1`.
    private(set) var localLevel: Float = 0
    /// The counterpart's level, once it has reported one.
    private(set) var remoteLevel: Float?

    @ObservationIgnored var onLocalLevelChange: ((Float) -> Void)?

    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var lastReportedLevel: Float?

    private static let interval: Duration = .seconds(1)

    func start() {
        guard loop == nil else { return }
        Device.enableBatteryMonitoring()
        loop = Task { [weak self] in
            while !Task.isCancelled, let self {
                self.refresh()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    func updateRemoteLevel(_ level: Float) {
        remoteLevel = level
    }

    /// Reports the current level again even if it has not changed,
    /// e.g. after the counterpart becomes reachable.
    func resendLocalLevel() {
        lastReportedLevel = nil
        refresh()
    }

    private func refresh() {
        let level = Device.batteryLevel
        localLevel = max(level, 0)
        guard level >= 0, level != lastReportedLevel else { return }
        lastReportedLevel = level
        onLocalLevelChange?(level)
    }
}
