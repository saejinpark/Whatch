//
//  ReactionDuel.swift
//  Whatch
//

import Foundation

/// One device's side of the reaction duel.
///
/// Each device shows "go" by its own clock and measures its own reaction time, so the
/// delay between the devices does not favour either player. They only exchange results.
struct ReactionDuel: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case idle
        /// Counting down to "go". Tapping now is a false start.
        case waiting
        case go
        /// This player has tapped.
        case finished
    }

    enum Outcome: Equatable, Sendable {
        case win
        case lose
        case draw
    }

    /// The result reported for tapping before "go".
    static let falseStart = -1

    private(set) var phase: Phase = .idle
    private(set) var round = 0
    private(set) var goAt: Date?
    /// Reaction times in milliseconds, or `falseStart`.
    private(set) var myTime: Int?
    private(set) var theirTime: Int?
    private(set) var wins = 0
    private(set) var losses = 0
    private var isCounted = false

    mutating func start(round: Int, delay: TimeInterval, now: Date) {
        self.round = round
        goAt = now.addingTimeInterval(max(delay, 0))
        myTime = nil
        theirTime = nil
        isCounted = false
        phase = .waiting
    }

    /// Moves from waiting to "go" once the time has come.
    mutating func tick(now: Date) {
        if phase == .waiting, let goAt, now >= goAt {
            phase = .go
        }
    }

    /// The player tapped. Returns the result to send to the other device, if the tap counted.
    mutating func tap(now: Date) -> Int? {
        tick(now: now)
        switch phase {
        case .waiting:
            myTime = Self.falseStart
        case .go:
            guard let goAt else { return nil }
            myTime = max(Int((now.timeIntervalSince(goAt) * 1000).rounded()), 0)
        case .idle, .finished:
            return nil
        }
        phase = .finished
        count()
        return myTime
    }

    /// The other device's result arrived. Results for other rounds are ignored.
    mutating func receive(round: Int, milliseconds: Int) {
        guard round == self.round, phase != .idle else { return }
        theirTime = milliseconds
        count()
    }

    /// Who won, once both results are in.
    var outcome: Outcome? {
        guard let myTime, let theirTime else { return nil }
        switch (myTime == Self.falseStart, theirTime == Self.falseStart) {
        case (true, true): return .draw
        case (true, false): return .lose
        case (false, true): return .win
        case (false, false):
            if myTime == theirTime { return .draw }
            return myTime < theirTime ? .win : .lose
        }
    }

    private mutating func count() {
        guard !isCounted, let outcome else { return }
        isCounted = true
        switch outcome {
        case .win: wins += 1
        case .lose: losses += 1
        case .draw: break
        }
    }
}
