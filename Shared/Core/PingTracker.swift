//
//  PingTracker.swift
//  Whatch
//

import Foundation

/// The bookkeeping behind the ping test, with time passed in so it can be tested.
///
/// One ping is in flight at a time. Call `tick` once a second: it returns the timestamp
/// to send when a new ping is due. Call `receivePong` when an answer arrives.
struct PingTracker: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        /// Nothing sent yet.
        case idle
        /// The first ping is in flight.
        case waiting
        /// The last ping was answered.
        case connected
        /// The counterpart is unreachable or the last ping timed out.
        case lost
    }

    private(set) var status: Status = .idle
    /// Round-trip time of the last answered ping, in seconds.
    private(set) var latency: TimeInterval?
    /// Most recent round-trip times, oldest first.
    private(set) var samples: [TimeInterval] = []
    private(set) var sentCount = 0
    private(set) var lostCount = 0
    private(set) var lastSentAt: Date?
    private(set) var lastAnsweredAt: Date?

    private var pending: Date?
    let timeout: TimeInterval
    let sampleLimit: Int

    init(timeout: TimeInterval = 5, sampleLimit: Int = 30) {
        self.timeout = timeout
        self.sampleLimit = sampleLimit
    }

    var average: TimeInterval? {
        samples.isEmpty ? nil : samples.reduce(0, +) / Double(samples.count)
    }

    var minimum: TimeInterval? { samples.min() }
    var maximum: TimeInterval? { samples.max() }

    /// Advances the clock. Returns the timestamp to put in a `.ping` when one should go out now.
    mutating func tick(now: Date, isReachable: Bool) -> TimeInterval? {
        if let pending {
            guard now.timeIntervalSince(pending) >= timeout else { return nil }
            self.pending = nil
            lostCount += 1
            status = .lost
        }
        guard isReachable else {
            status = .lost
            return nil
        }
        pending = now
        lastSentAt = now
        sentCount += 1
        if status == .idle {
            status = .waiting
        }
        return now.timeIntervalSince1970
    }

    /// Records an answer. Returns `false` for answers to pings that already timed out.
    @discardableResult
    mutating func receivePong(sentAt: TimeInterval, now: Date) -> Bool {
        guard let pending, pending.timeIntervalSince1970 == sentAt else { return false }
        self.pending = nil
        let roundTrip = max(now.timeIntervalSince(pending), 0)
        latency = roundTrip
        lastAnsweredAt = now
        samples.append(roundTrip)
        if samples.count > sampleLimit {
            samples.removeFirst(samples.count - sampleLimit)
        }
        status = .connected
        return true
    }

    mutating func reset() {
        self = PingTracker(timeout: timeout, sampleLimit: sampleLimit)
    }
}
