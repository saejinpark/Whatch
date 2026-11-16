//
//  LinkSync.swift
//  Whatch
//

import Foundation

/// Tracks whether the counterpart has confirmed hearing where this device stands.
///
/// A message sent the instant an app returns to the screen is easily lost: the link is
/// often not up yet, and WatchConnectivity does not always say when it comes back. So the
/// greeting is repeated until one copy is acknowledged, instead of being sent once and hoped for.
struct LinkSync: Equatable {
    /// Proof of which request an attempt belongs to. An attempt overtaken by a newer request is ignored.
    struct Ticket: Equatable {
        fileprivate let generation: Int
    }

    /// How long to wait for an answer before trying again. A link that is just waking up can take
    /// several seconds to carry its first message, and everything sent meanwhile arrives at once.
    static let stallTimeout: TimeInterval = 6

    /// A greeting is owed and has not been confirmed.
    private(set) var isPending = false
    private var generation = 0
    private var attemptedAt: Date?

    /// This device's situation changed, or the link came back: the counterpart needs to hear again.
    mutating func request() {
        isPending = true
        generation += 1
        attemptedAt = nil
    }

    /// Returns a ticket when a greeting should go out now, or `nil` when none is owed or one is still in flight.
    mutating func begin(now: Date) -> Ticket? {
        guard isPending else { return nil }
        if let attemptedAt, now.timeIntervalSince(attemptedAt) < Self.stallTimeout { return nil }
        attemptedAt = now
        return Ticket(generation: generation)
    }

    /// Records how an attempt ended. Returns `true` when it settled the current request.
    mutating func finish(_ ticket: Ticket, delivered: Bool) -> Bool {
        guard ticket.generation == generation, isPending else { return false }
        attemptedAt = nil
        guard delivered else { return false }
        isPending = false
        return true
    }
}
