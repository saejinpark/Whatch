//
//  ConnectivitySession.swift
//  Whatch
//

import Foundation
import WatchConnectivity

/// The single owner of `WCSession` for the app.
///
/// `WCSession` has exactly one delegate, so everything that talks to the counterpart
/// device goes through this object. Pings are answered here; every other decoded
/// message is handed to `onMessage` on the main actor.
@MainActor
@Observable
final class ConnectivitySession: NSObject {
    private(set) var isReachable = false
    private(set) var isActivated = false

    @ObservationIgnored var onMessage: ((WatchMessage) -> Void)?
    @ObservationIgnored var onReachabilityChange: ((Bool) -> Void)?

    @ObservationIgnored private let session: WCSession? = WCSession.isSupported() ? .default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func send(_ message: WatchMessage) {
        guard let session, session.activationState == .activated, session.isReachable else {
            Log.connectivity.debug("Dropped \(String(describing: message)): counterpart not reachable")
            return
        }
        session.sendMessage(message.payload, replyHandler: nil) { error in
            Log.connectivity.error("Send failed: \(error.localizedDescription)")
        }
    }

    private func receive(_ message: WatchMessage) {
        if case .ping(let sentAt) = message {
            send(.pong(sentAt: sentAt))
            return
        }
        onMessage?(message)
    }

    private func updateReachability(_ reachable: Bool) {
        guard reachable != isReachable else { return }
        isReachable = reachable
        onReachabilityChange?(reachable)
    }
}

extension ConnectivitySession: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            Log.connectivity.error("Activation failed: \(error.localizedDescription)")
        }
        let activated = activationState == .activated
        let reachable = session.isReachable
        Task { @MainActor in
            self.isActivated = activated
            self.updateReachability(reachable)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.updateReachability(reachable)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let decoded = WatchMessage(payload: message) else {
            Log.connectivity.warning("Ignored unknown message: \(message.keys.joined(separator: ","))")
            return
        }
        Task { @MainActor in
            self.receive(decoded)
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required when the user switches to another paired Watch.
        session.activate()
    }
    #endif
}
