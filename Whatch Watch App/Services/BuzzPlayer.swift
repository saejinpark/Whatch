//
//  BuzzPlayer.swift
//  Whatch Watch App
//

import Foundation
import WatchKit

/// Plays a tap pattern sent from the iPhone on the Watch's Taptic Engine.
@MainActor
@Observable
final class BuzzPlayer {
    /// The pattern being played, as `.`, `-`, space and `/`.
    private(set) var pattern = ""
    /// Index of the symbol playing now, or `nil` when idle.
    private(set) var position: Int?

    @ObservationIgnored private var task: Task<Void, Never>?

    func play(_ pattern: String) {
        task?.cancel()
        guard !pattern.isEmpty else {
            position = nil
            return
        }
        self.pattern = pattern
        task = Task { [weak self] in
            for (index, symbol) in pattern.enumerated() {
                guard !Task.isCancelled, let self else { return }
                self.position = index
                // The Watch has no adjustable vibration length, so a dot is its lightest
                // tap and a dash its long single one, with a longer pause after it.
                switch symbol {
                case ".":
                    WKInterfaceDevice.current().play(.click)
                    try? await Task.sleep(for: .milliseconds(280))
                case "-":
                    WKInterfaceDevice.current().play(.start)
                    try? await Task.sleep(for: .milliseconds(650))
                case "/":
                    try? await Task.sleep(for: .milliseconds(750))
                default:
                    try? await Task.sleep(for: .milliseconds(400))
                }
            }
            try? await Task.sleep(for: .milliseconds(1200))
            if !Task.isCancelled {
                self?.position = nil
            }
        }
    }
}
