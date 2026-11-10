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
///
/// Two channels are used:
/// - `send` delivers immediately, but only while the counterpart is reachable.
/// - `publish` stores the latest state so the counterpart finds it whenever it next runs.
@MainActor
@Observable
final class ConnectivitySession: NSObject {
    /// `false` on devices that cannot pair with a Watch, such as iPad.
    let isSupported = WCSession.isSupported()
    private(set) var isActivated = false
    private(set) var isReachable = false
    /// iPhone only: whether a Watch is paired. Always `true` on the Watch.
    private(set) var isPaired = true
    /// Whether the counterpart app is installed on the other device.
    private(set) var isCounterpartInstalled = true

    /// `isLive` is `false` for state restored from the stored application context.
    @ObservationIgnored var onMessage: ((_ message: WatchMessage, _ isLive: Bool) -> Void)?
    @ObservationIgnored var onReachabilityChange: ((Bool) -> Void)?

    @ObservationIgnored private let session: WCSession? = WCSession.isSupported() ? .default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    /// Sends now. Returns `false` when the counterpart cannot be reached.
    @discardableResult
    func send(_ message: WatchMessage) -> Bool {
        guard let session, session.activationState == .activated, session.isReachable else {
            return false
        }
        session.sendMessage(message.payload, replyHandler: nil) { error in
            Log.connectivity.error("Send failed: \(error.localizedDescription)")
        }
        return true
    }

    /// Stores `state` for the counterpart to pick up, even if it is not running right now.
    func publish(_ state: DeviceState) {
        guard let session, session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext(WatchMessage.state(state).payload)
        } catch {
            Log.connectivity.error("Publishing state failed: \(error.localizedDescription)")
        }
    }

    private func receive(_ message: WatchMessage, isLive: Bool) {
        if case .ping(let sentAt) = message {
            send(.pong(sentAt: sentAt))
            return
        }
        onMessage?(message, isLive)
    }

    private func apply(_ snapshot: Snapshot) {
        isActivated = snapshot.isActivated
        isPaired = snapshot.isPaired
        isCounterpartInstalled = snapshot.isCounterpartInstalled
        guard snapshot.isReachable != isReachable else { return }
        isReachable = snapshot.isReachable
        onReachabilityChange?(snapshot.isReachable)
    }
}

/// The session facts we mirror, captured on WatchConnectivity's queue and applied on the main actor.
private struct Snapshot: Sendable {
    let isActivated: Bool
    let isReachable: Bool
    let isPaired: Bool
    let isCounterpartInstalled: Bool

    init(_ session: WCSession) {
        isActivated = session.activationState == .activated
        isReachable = session.isReachable
        #if os(iOS)
        isPaired = session.isPaired
        isCounterpartInstalled = session.isWatchAppInstalled
        #else
        isPaired = true
        isCounterpartInstalled = session.isCompanionAppInstalled
        #endif
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
        let snapshot = Snapshot(session)
        let stored = WatchMessage(payload: session.receivedApplicationContext)
        Task { @MainActor in
            self.apply(snapshot)
            if let stored {
                self.receive(stored, isLive: false)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let snapshot = Snapshot(session)
        Task { @MainActor in
            self.apply(snapshot)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let decoded = WatchMessage(payload: message) else {
            Log.connectivity.warning("Ignored unknown message: \(message.keys.sorted().joined(separator: ","))")
            return
        }
        Task { @MainActor in
            self.receive(decoded, isLive: true)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let decoded = WatchMessage(payload: applicationContext) else { return }
        Task { @MainActor in
            self.receive(decoded, isLive: false)
        }
    }

    #if os(iOS)
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let snapshot = Snapshot(session)
        Task { @MainActor in
            self.apply(snapshot)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required when the user switches to another paired Watch.
        session.activate()
    }
    #endif
}
