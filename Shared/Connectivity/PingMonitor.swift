//
//  PingMonitor.swift
//  Whatch
//

import Foundation

/// Runs the ping test: drives a `PingTracker` once a second and sends the pings it asks for.
@MainActor
@Observable
final class PingMonitor {
    private(set) var tracker = PingTracker()

    @ObservationIgnored private let session: ConnectivitySession
    @ObservationIgnored private var loop: Task<Void, Never>?

    private static let interval: Duration = .seconds(1)

    init(session: ConnectivitySession) {
        self.session = session
    }

    var isRunning: Bool {
        loop != nil
    }

    func start() {
        guard loop == nil else { return }
        tracker.reset()
        loop = Task { [weak self] in
            while !Task.isCancelled, let self {
                self.tick()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    func handlePong(sentAt: TimeInterval) {
        tracker.receivePong(sentAt: sentAt, now: Date())
    }

    private func tick() {
        if let sentAt = tracker.tick(now: Date(), isReachable: session.isReachable) {
            session.send(.ping(sentAt: sentAt))
        }
    }
}
