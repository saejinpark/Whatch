//
//  LatestSender.swift
//  Whatch
//

import Foundation

/// Sends a stream of values where only the newest one matters.
///
/// One message is in flight at a time. Values offered meanwhile replace each other, and
/// the survivor goes out when the previous one is acknowledged. A slow link therefore
/// gets fewer, fresher messages instead of a growing queue of stale ones.
@MainActor
final class LatestSender {
    private let session: ConnectivitySession
    private let minimumInterval: TimeInterval
    private var pending: WatchMessage?
    private var inFlightSince: Date?
    private var lastSentAt = Date.distantPast

    /// How long to wait for an acknowledgement before sending anyway.
    private static let stallTimeout: TimeInterval = 1.5

    init(session: ConnectivitySession, minimumInterval: TimeInterval = 0) {
        self.session = session
        self.minimumInterval = minimumInterval
    }

    func offer(_ message: WatchMessage) {
        pending = message
        flush()
    }

    func cancel() {
        pending = nil
    }

    private func flush() {
        guard let message = pending else { return }
        let now = Date()
        if let inFlightSince, now.timeIntervalSince(inFlightSince) < Self.stallTimeout { return }
        guard now.timeIntervalSince(lastSentAt) >= minimumInterval else { return }

        pending = nil
        inFlightSince = now
        lastSentAt = now
        session.sendAcknowledged(message) { [weak self] _ in
            guard let self else { return }
            if inFlightSince == now { inFlightSince = nil }
            flush()
        }
    }
}
