//
//  PingMonitor.swift
//  Whatch
//

import Foundation

/// Sends a ping every second while running and reports whether, and how fast, the
/// counterpart answered. Feed incoming `.pong` messages to `handle(_:)`.
@MainActor
@Observable
final class PingMonitor {
    private(set) var status: PingStatus = .pending
    private(set) var lastPingSentAt: Date?
    private(set) var lastPongReceivedAt: Date?
    private(set) var latency: TimeInterval?

    @ObservationIgnored private let session: ConnectivitySession
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var timeout: Task<Void, Never>?

    private static let interval: Duration = .seconds(1)
    private static let timeoutInterval: Duration = .seconds(1)

    init(session: ConnectivitySession) {
        self.session = session
    }

    func start() {
        guard loop == nil else { return }
        status = .pending
        loop = Task { [weak self] in
            while !Task.isCancelled, let self {
                self.ping()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
        timeout?.cancel()
        timeout = nil
    }

    func handle(_ message: WatchMessage) {
        guard case .pong(let sentAt) = message else { return }
        timeout?.cancel()
        let now = Date()
        lastPongReceivedAt = now
        latency = now.timeIntervalSince(Date(timeIntervalSince1970: sentAt))
        status = .good
    }

    private func ping() {
        guard session.isReachable else {
            status = .bad
            return
        }
        let now = Date()
        lastPingSentAt = now
        session.send(.ping(sentAt: now.timeIntervalSince1970))

        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: Self.timeoutInterval)
            guard !Task.isCancelled else { return }
            self?.status = .bad
        }
    }
}
