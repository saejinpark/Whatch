//
//  DuelController.swift
//  Whatch
//

import Foundation

/// Runs this device's side of the reaction duel and exchanges results with the other.
@MainActor
@Observable
final class DuelController {
    private(set) var duel = ReactionDuel()

    @ObservationIgnored var send: ((WatchMessage) -> Void)?
    @ObservationIgnored private var timer: Task<Void, Never>?

    /// Starts a round on both devices. Without a connection it becomes solo practice.
    func startRound() {
        let round = Int.random(in: 1...999_999)
        let delay = Double.random(in: 2...5)
        send?(.duelStart(round: round, delay: delay))
        begin(round: round, delay: delay)
    }

    /// The other device started a round.
    func receiveStart(round: Int, delay: TimeInterval) {
        begin(round: round, delay: delay)
    }

    func tap() {
        guard let result = duel.tap(now: Date()) else { return }
        timer?.cancel()
        send?(.duelResult(round: duel.round, milliseconds: result))
    }

    func receiveResult(round: Int, milliseconds: Int) {
        duel.receive(round: round, milliseconds: milliseconds)
    }

    private func begin(round: Int, delay: TimeInterval) {
        duel.start(round: round, delay: delay, now: Date())
        timer?.cancel()
        timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            // A sleep may end a hair early; poll until the moment has really come.
            while !Task.isCancelled, let self, self.duel.phase == .waiting {
                self.duel.tick(now: Date())
                if self.duel.phase == .waiting {
                    try? await Task.sleep(for: .milliseconds(4))
                }
            }
        }
    }
}
