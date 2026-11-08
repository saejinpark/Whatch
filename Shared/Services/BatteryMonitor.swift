//
//  BatteryMonitor.swift
//  Whatch
//

import Foundation

/// Keeps this device's battery reading current while running.
@MainActor
@Observable
final class BatteryMonitor {
    private(set) var reading = BatteryReading()

    /// Called when a poll finds a different reading.
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private var loop: Task<Void, Never>?

    private static let interval: Duration = .seconds(5)

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled, let self {
                if self.refresh() {
                    self.onChange?()
                }
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    /// Reads the battery now. Returns `true` when the reading changed.
    @discardableResult
    func refresh() -> Bool {
        let latest = Device.batteryReading()
        guard latest != reading else { return false }
        reading = latest
        return true
    }
}
