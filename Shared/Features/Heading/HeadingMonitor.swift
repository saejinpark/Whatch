//
//  HeadingMonitor.swift
//  Whatch
//

import CoreLocation
import Foundation

/// Tracks this device's compass heading and keeps the counterpart's last reported heading.
@MainActor
@Observable
final class HeadingMonitor: NSObject {
    /// This device's heading in degrees, or `nil` until the compass has a fix.
    private(set) var heading: CLLocationDirection?
    /// The counterpart's last reported true heading in degrees.
    private(set) var remoteHeading: CLLocationDirection = 0

    /// Called whenever the heading moved at least `sendThreshold` degrees since the last call.
    @ObservationIgnored var onHeadingChange: ((CLLocationDirection) -> Void)?

    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private var lastReportedHeading: CLLocationDirection?
    private static let sendThreshold: CLLocationDirection = 1

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.headingOrientation = .portrait
    }

    var isAvailable: Bool {
        CLLocationManager.headingAvailable()
    }

    func start() {
        guard isAvailable else {
            Log.sensors.warning("Heading is not available on this device")
            return
        }
        // True north needs a location fix; magnetic heading works without authorization.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingHeading()
    }

    func stop() {
        locationManager.stopUpdatingHeading()
    }

    func updateRemoteHeading(_ degrees: CLLocationDirection) {
        remoteHeading = degrees
    }

    private func record(_ newHeading: CLHeading) {
        // `trueHeading` is negative when it cannot be computed; fall back to magnetic north.
        let degrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        guard degrees >= 0 else { return }
        heading = degrees

        if let last = lastReportedHeading, abs(degrees - last) < Self.sendThreshold {
            return
        }
        lastReportedHeading = degrees
        onHeadingChange?(degrees)
    }
}

extension HeadingMonitor: CLLocationManagerDelegate {
    // The manager is created on the main actor, so CoreLocation calls back on the main thread.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated {
            record(newHeading)
        }
    }
}
