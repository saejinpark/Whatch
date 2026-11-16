//
//  MeasureController.swift
//  Whatch
//

import Foundation

/// Runs a length or height measurement on both devices at once, so both end on the same number.
///
/// Whichever device is asked starts the other too. The first to get an answer sends it across
/// and the other shows it as well, instead of each device arriving at a number of its own.
@MainActor
@Observable
final class MeasureController {
    private(set) var measure = SteadyDistance()
    private(set) var kind = MeasureKind.length
    /// The time of the latest tick, so the countdown redraws.
    private(set) var now = Date()

    @ObservationIgnored var send: ((WatchMessage) -> Void)?

    @ObservationIgnored private let ranging: RangingService
    /// Names the measurement, so answers to an abandoned one are ignored. Later ones are larger.
    @ObservationIgnored private var id = 0
    @ObservationIgnored private var hasPeerResult = false
    @ObservationIgnored private var loop: Task<Void, Never>?

    init(ranging: RangingService) {
        self.ranging = ranging
    }

    /// Starts a measurement here and on the other device.
    func start(_ kind: MeasureKind) {
        let id = max(Int(Date().timeIntervalSince1970 * 1000), self.id + 1)
        send?(.measureStart(kind, id: id))
        begin(kind, id: id)
    }

    /// Ends the measurement or puts its result away. One still running ends on the other device too.
    func stop() {
        if measure.isRunning {
            send?(.measureStop(id: id))
        }
        end()
    }

    /// The other device started a measurement.
    func receiveStart(_ kind: MeasureKind, id: Int) {
        guard ranging.status == .ranging else { return }
        // Both were asked at the same moment: the later one stands on both.
        if measure.isRunning, id <= self.id { return }
        begin(kind, id: id)
    }

    func receiveResult(id: Int, meters: Double, isSteady: Bool) {
        guard id == self.id, !hasPeerResult, measure.phase != .idle, meters.isFinite else { return }
        hasPeerResult = true
        change { $0.adopt(SteadyDistance.Result(meters: meters, isSteady: isSteady)) }
    }

    func receiveStop(id: Int) {
        guard id == self.id, measure.isRunning else { return }
        end()
    }

    /// A measurement in progress means nothing without readings.
    func rangingChanged() {
        if ranging.status != .ranging, measure.isRunning {
            end()
        }
    }

    private func begin(_ kind: MeasureKind, id: Int) {
        self.kind = kind
        self.id = id
        hasPeerResult = false
        now = Date()
        measure.start(now: now)
        loop?.cancel()
        loop = Task { [weak self] in
            await self?.run()
        }
    }

    private func end() {
        loop?.cancel()
        loop = nil
        measure.reset()
    }

    /// Feeds the measurement while it runs: every new reading once, and a tick in between.
    private func run() async {
        var seen = ranging.readingCount
        while !Task.isCancelled, measure.isRunning {
            let date = Date()
            if ranging.readingCount != seen, let distance = ranging.distance {
                seen = ranging.readingCount
                change { $0.add(distance, now: date) }
            } else {
                change { $0.tick(now: date) }
            }
            now = date
            if case .done(let result) = measure.phase, !hasPeerResult {
                send?(.measureResult(id: id, meters: result.meters, isSteady: result.isSteady))
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Whoever is measuring is not looking at the screen, so each step is felt instead.
    private func change(_ body: (inout SteadyDistance) -> Void) {
        let old = measure.phase
        body(&measure)
        let new = measure.phase
        guard new != old else { return }
        switch new {
        case .measuring:
            Haptics.play(.begin)
        case .done(let result):
            // Two answers that crossed only settle the number; the step was already felt.
            if case .done = old { break }
            Haptics.play(result.isSteady ? .done : .trouble)
        case .failed:
            Haptics.play(.trouble)
        case .idle, .preparing:
            break
        }
    }
}
