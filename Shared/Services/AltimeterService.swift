//
//  AltimeterService.swift
//  Whatch
//

import CoreMotion
import Foundation

/// Reads this device's barometer while running.
@MainActor
@Observable
final class AltimeterService {
    enum Status: Equatable {
        case idle
        case running
        /// This device has no barometer.
        case unavailable
        /// Motion & Fitness access was refused.
        case denied
    }

    private(set) var status: Status = .idle
    /// Air pressure in kPa, once there is a reading.
    private(set) var pressure: Double?

    @ObservationIgnored var onChange: ((Double) -> Void)?
    @ObservationIgnored private let altimeter = CMAltimeter()
    @ObservationIgnored private var simulation: Task<Void, Never>?

    func start() {
        guard status != .running else { return }
        #if targetEnvironment(simulator)
        status = .running
        startSimulation()
        #else
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            status = .unavailable
            return
        }
        let authorization = CMAltimeter.authorizationStatus()
        guard authorization != .denied, authorization != .restricted else {
            status = .denied
            return
        }
        status = .running
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            let kPa = data?.pressure.doubleValue
            let failed = error != nil
            // Updates are delivered on the main queue, as requested above.
            MainActor.assumeIsolated {
                guard let self else { return }
                if let kPa {
                    self.record(kPa)
                } else if failed, self.pressure == nil {
                    self.status = CMAltimeter.authorizationStatus() == .denied ? .denied : .unavailable
                }
            }
        }
        #endif
    }

    func stop() {
        guard status == .running else { return }
        simulation?.cancel()
        simulation = nil
        altimeter.stopRelativeAltitudeUpdates()
        status = .idle
        pressure = nil
    }

    private func record(_ kPa: Double) {
        pressure = kPa
        onChange?(kPa)
    }

    /// Simulators have no barometer; drift slowly so the screens can be checked.
    private func startSimulation() {
        simulation = Task { [weak self] in
            var time = 0.0
            #if os(watchOS)
            let base = 101.296 // The simulated Watch sits about 35 cm above the simulated iPhone.
            #else
            let base = 101.300
            #endif
            while !Task.isCancelled, let self {
                self.record(base + 0.0012 * sin(time / 2))
                time += 1
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
