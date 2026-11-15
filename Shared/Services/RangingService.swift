//
//  RangingService.swift
//  Whatch
//

import Foundation
import NearbyInteraction

/// Measures the distance to the other device with ultra-wideband, where both have the chip.
///
/// The two devices exchange Nearby Interaction discovery tokens over the Watch link:
/// whoever opens the radar sends an offer, and a device that is already ranging answers.
@MainActor
@Observable
final class RangingService: NSObject {
    enum Status: Equatable {
        case idle
        /// This device cannot measure precise distance.
        case unsupported
        /// Waiting for the other device, or for it to come into range.
        case searching
        case ranging
        /// Nearby Interaction access was refused.
        case denied
        case failed
    }

    private(set) var status: Status = .idle
    /// Distance to the other device in metres.
    private(set) var distance: Double?
    /// iPhone only: where the other device is, in degrees to the right of straight ahead.
    private(set) var bearing: Double?
    /// Whether the radar screen is open on this device.
    private(set) var isStarted = false

    /// Called with this device's token; `isAnswer` is `false` when the other device should reply.
    @ObservationIgnored var sendToken: ((_ token: Data, _ isAnswer: Bool) -> Void)?

    @ObservationIgnored private var session: NISession?
    @ObservationIgnored private var peerToken: Data?
    @ObservationIgnored private var activePeerToken: Data?
    @ObservationIgnored private var restarts = 0
    @ObservationIgnored private var simulation: Task<Void, Never>?

    static var isSupported: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
        #endif
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        guard Self.isSupported else {
            status = .unsupported
            return
        }
        status = .searching
        restarts = 0
        makeSession()
        sendOwnToken(isAnswer: false)
        run()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        simulation?.cancel()
        simulation = nil
        session?.invalidate()
        session = nil
        activePeerToken = nil
        distance = nil
        bearing = nil
        status = .idle
    }

    /// The other device's token arrived.
    func receive(token: Data, isAnswer: Bool) {
        peerToken = token
        guard isStarted, status != .unsupported else { return }
        if !isAnswer {
            sendOwnToken(isAnswer: true)
        }
        run()
    }

    // MARK: Session

    private func makeSession() {
        #if !targetEnvironment(simulator)
        let session = NISession()
        session.delegate = self
        self.session = session
        activePeerToken = nil
        #endif
    }

    private func sendOwnToken(isAnswer: Bool) {
        #if targetEnvironment(simulator)
        sendToken?(Data("simulator".utf8), isAnswer)
        #else
        guard let token = session?.discoveryToken,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            Log.sensors.error("No Nearby Interaction token to send")
            return
        }
        sendToken?(data, isAnswer)
        #endif
    }

    /// Starts ranging against the newest token from the other device.
    private func run() {
        guard isStarted, let peerToken, peerToken != activePeerToken else { return }
        #if targetEnvironment(simulator)
        activePeerToken = peerToken
        startSimulation()
        #else
        guard let session,
              let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: peerToken) else {
            return
        }
        activePeerToken = peerToken
        session.run(NINearbyPeerConfiguration(peerToken: token))
        #endif
    }

    private func update(distance: Float?, bearing: Double?) {
        guard isStarted else { return }
        self.distance = distance.map(Double.init)
        self.bearing = bearing
        status = distance == nil ? .searching : .ranging
    }

    private func lostPeer() {
        guard isStarted else { return }
        distance = nil
        bearing = nil
        status = .searching
        // Keep trying: the other device may only have moved out of range.
        activePeerToken = nil
        run()
    }

    private func invalidated(denied: Bool) {
        guard isStarted else { return }
        session = nil
        distance = nil
        bearing = nil
        if denied {
            status = .denied
        } else if restarts < 3 {
            restarts += 1
            status = .searching
            makeSession()
            sendOwnToken(isAnswer: false)
        } else {
            status = .failed
        }
    }

    /// Simulators have no ultra-wideband radio; wander so the screens can be checked.
    private func startSimulation() {
        simulation?.cancel()
        simulation = Task { [weak self] in
            var time = 0.0
            while !Task.isCancelled, let self {
                #if os(iOS)
                let bearing: Double? = 35 * sin(time / 4)
                #else
                let bearing: Double? = nil
                #endif
                self.update(distance: Float(1.3 + 0.9 * sin(time / 2.5)), bearing: bearing)
                time += 0.2
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }
}

extension RangingService: NISessionDelegate {
    nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first else { return }
        let distance = object.distance
        var bearing: Double?
        #if os(iOS)
        if let direction = object.direction {
            // The device looks down its negative z axis; x points to its right.
            bearing = Double(atan2(direction.x, -direction.z)) * 180 / .pi
        } else if let angle = object.horizontalAngle {
            bearing = Double(angle) * 180 / .pi
        }
        #endif
        let result = bearing
        Task { @MainActor in
            self.update(distance: distance, bearing: result)
        }
    }

    nonisolated func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject],
                             reason: NINearbyObject.RemovalReason) {
        Task { @MainActor in
            self.lostPeer()
        }
    }

    nonisolated func sessionWasSuspended(_ session: NISession) {
        Task { @MainActor in
            self.update(distance: nil, bearing: nil)
        }
    }

    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        Task { @MainActor in
            self.lostPeer()
        }
    }

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        let denied = (error as? NIError)?.code == .userDidNotAllow
        Task { @MainActor in
            self.invalidated(denied: denied)
        }
    }
}
