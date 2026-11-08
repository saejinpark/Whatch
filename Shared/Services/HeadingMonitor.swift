//
//  HeadingMonitor.swift
//  Whatch
//

import CoreLocation
import Foundation

/// Tracks this device's compass heading while running.
@MainActor
@Observable
final class HeadingMonitor: NSObject {
    /// Heading in degrees, or `nil` until the compass has a reading.
    private(set) var heading: CLLocationDirection?
    /// Whether `heading` is relative to true north (needs location access) or magnetic north.
    private(set) var isTrueNorth = false

    /// Called when the heading moved at least `reportThreshold` degrees since the last call,
    /// at most once per `reportInterval`.
    @ObservationIgnored var onChange: ((CLLocationDirection) -> Void)?

    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private var lastReported: CLLocationDirection?
    @ObservationIgnored private var lastReportedAt = Date.distantPast
    @ObservationIgnored private var isRunning = false
    @ObservationIgnored private var simulation: Task<Void, Never>?
    private static let reportThreshold: CLLocationDirection = 1
    private static let reportInterval: TimeInterval = 0.2

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = kCLHeadingFilterNone
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        #if targetEnvironment(simulator)
        startSimulation()
        #else
        guard CLLocationManager.headingAvailable() else {
            Log.sensors.warning("Heading is not available on this device")
            isRunning = false
            return
        }
        // True north needs a location fix; without access we fall back to magnetic north.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingHeading()
        #endif
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        simulation?.cancel()
        simulation = nil
        locationManager.stopUpdatingHeading()
        heading = nil
        lastReported = nil
    }

    private func record(trueHeading: CLLocationDirection, magneticHeading: CLLocationDirection) {
        // `trueHeading` is negative when it cannot be computed.
        let usesTrueNorth = trueHeading >= 0
        let degrees = usesTrueNorth ? trueHeading : magneticHeading
        guard degrees >= 0 else { return }
        heading = degrees
        isTrueNorth = usesTrueNorth

        // The compass keeps reporting while at rest, so a change skipped here goes out a moment later.
        let now = Date()
        guard now.timeIntervalSince(lastReportedAt) >= Self.reportInterval else { return }
        if let lastReported, abs(HeadingMath.difference(from: lastReported, to: degrees)) < Self.reportThreshold {
            return
        }
        lastReported = degrees
        lastReportedAt = now
        onChange?(degrees)
    }

    /// Simulators have no compass; sweep slowly so the screens can be checked.
    private func startSimulation() {
        simulation = Task { [weak self] in
            var degrees = 40.0
            while !Task.isCancelled, let self {
                self.record(trueHeading: degrees, magneticHeading: degrees)
                degrees = HeadingMath.normalized(degrees + 1.5)
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}

extension HeadingMonitor: CLLocationManagerDelegate {
    // The manager is created on the main actor, so CoreLocation calls back on the main thread.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        MainActor.assumeIsolated {
            record(trueHeading: trueHeading, magneticHeading: magneticHeading)
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
}
