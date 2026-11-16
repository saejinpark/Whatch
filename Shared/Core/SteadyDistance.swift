//
//  SteadyDistance.swift
//  Whatch
//

import Foundation

/// Turns a jittery stream of distance readings into one number, taken once the devices hold still.
///
/// Whoever is measuring cannot look at a screen with both arms out, so the measurement runs
/// itself: a few seconds to get into position, then it waits for the readings to settle and
/// keeps the middle one. If they never settle it still answers, and says the number is rough.
struct SteadyDistance: Equatable {
    struct Result: Equatable {
        let meters: Double
        /// `false` when the readings never settled, so the number is only the latest middle value.
        let isSteady: Bool
    }

    enum Phase: Equatable {
        case idle
        /// Time to get into position. Readings are ignored.
        case preparing
        case measuring
        case done(Result)
        /// No reading arrived at all.
        case failed
    }

    /// Seconds to get into position before readings count.
    static let preparation: TimeInterval = 3
    /// Readings newer than this are compared with each other.
    static let window: TimeInterval = 2
    static let minimumSamples = 3
    /// The compared readings must span at least this much of the window.
    static let minimumCoverage: TimeInterval = 1.2
    /// Largest gap between the compared readings that still counts as holding still, in metres.
    static let steadySpread = 0.06
    /// Seconds to wait for the readings to settle before answering anyway.
    static let timeout: TimeInterval = 10

    private struct Sample: Equatable {
        let time: Date
        let meters: Double
    }

    private(set) var phase: Phase = .idle
    private var startedAt = Date.distantPast
    private var samples: [Sample] = []

    /// Whether a measurement is under way and needs readings and ticks.
    var isRunning: Bool {
        phase == .preparing || phase == .measuring
    }

    mutating func start(now: Date) {
        phase = .preparing
        startedAt = now
        samples = []
    }

    mutating func reset() {
        phase = .idle
        samples = []
    }

    /// Whole seconds left to get into position: 3, 2, 1, then 0.
    func countdown(now: Date) -> Int {
        guard phase == .preparing else { return 0 }
        return max(0, Int((Self.preparation - now.timeIntervalSince(startedAt)).rounded(.up)))
    }

    /// The other device finished this measurement, first or at the same moment. Both screens must
    /// end on one number, so its answer replaces a measurement still running here, and two
    /// answers that crossed on the way meet in the middle unless only one of them held still.
    mutating func adopt(_ peer: Result) {
        switch phase {
        case .idle:
            break
        case .preparing, .measuring, .failed:
            phase = .done(peer)
        case .done(let own):
            if own.isSteady == peer.isSteady {
                phase = .done(Result(meters: (own.meters + peer.meters) / 2, isSteady: own.isSteady))
            } else {
                phase = .done(own.isSteady ? own : peer)
            }
        }
    }

    /// Call for every new distance reading.
    mutating func add(_ meters: Double, now: Date) {
        tick(now: now)
        guard phase == .measuring else { return }
        samples.append(Sample(time: now, meters: meters))
        tick(now: now)
    }

    /// Call a few times a second, so the phases advance even when no reading arrives.
    mutating func tick(now: Date) {
        let elapsed = now.timeIntervalSince(startedAt)
        if phase == .preparing, elapsed >= Self.preparation {
            phase = .measuring
            samples = []
        }
        guard phase == .measuring else { return }

        samples.removeAll { now.timeIntervalSince($0.time) > Self.window }
        if isSteady, let middle {
            phase = .done(Result(meters: middle, isSteady: true))
        } else if elapsed >= Self.preparation + Self.timeout {
            phase = middle.map { .done(Result(meters: $0, isSteady: false)) } ?? .failed
        }
    }

    private var isSteady: Bool {
        guard samples.count >= Self.minimumSamples, let first = samples.first, let last = samples.last,
              last.time.timeIntervalSince(first.time) >= Self.minimumCoverage,
              let low = samples.map(\.meters).min(), let high = samples.map(\.meters).max() else {
            return false
        }
        return high - low <= Self.steadySpread
    }

    /// The middle reading, which one stray value cannot move.
    private var middle: Double? {
        let sorted = samples.map(\.meters).sorted()
        guard !sorted.isEmpty else { return nil }
        let half = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[half - 1] + sorted[half]) / 2 : sorted[half]
    }
}

/// What a measurement is for.
enum MeasureKind: String, Sendable {
    /// The distance between the two devices.
    case length
    /// A height, estimated from arm span.
    case height
}

/// One distance from two devices that each measure it on their own.
///
/// Ultra-wideband gives each device its own estimate of how far the other is, and the two
/// can sit several centimetres apart. Each device tells the other what it reads, and both
/// show the average, so the two screens agree.
struct PairedDistance: Equatable {
    /// A reading from the other device older than this no longer describes where the devices are.
    static let peerLifetime: TimeInterval = 1.5

    /// This device's own latest reading, in metres.
    private(set) var own: Double?
    private var peer: Double?
    private var peerAt = Date.distantPast

    mutating func updateOwn(_ meters: Double?) {
        own = meters
    }

    mutating func updatePeer(_ meters: Double, now: Date) {
        peer = meters
        peerAt = now
    }

    mutating func clear() {
        own = nil
        peer = nil
        peerAt = .distantPast
    }

    /// The other device's reading, while it is fresh.
    func peer(now: Date) -> Double? {
        now.timeIntervalSince(peerAt) <= Self.peerLifetime ? peer : nil
    }

    /// The distance to show: the average of both readings, or this device's own while the other is silent.
    func value(now: Date) -> Double? {
        guard let own else { return nil }
        guard let peer = peer(now: now) else { return own }
        return (own + peer) / 2
    }
}

/// Estimates height from arm span, which on average is about the same length.
///
/// The devices measure from the wrist with the Watch to the hand holding the iPhone, which
/// is shorter than fingertip to fingertip. The offset makes up the difference; measuring
/// someone whose height is known replaces the default with their own.
enum ArmSpan {
    /// Wrist to fingertip on the Watch side, plus the part of the other hand beyond the iPhone, for an average adult.
    static let defaultOffset = 0.27
    /// Offsets outside this are a mistyped height or a bad reading, not a person.
    static let plausibleOffsets = -0.1...0.7

    static func height(distance: Double, offset: Double) -> Double {
        distance + offset
    }

    /// The offset that makes `distance` come out as `height`, or `nil` when the two cannot belong together.
    static func offset(height: Double, distance: Double) -> Double? {
        let offset = height - distance
        return plausibleOffsets.contains(offset) ? offset : nil
    }
}
