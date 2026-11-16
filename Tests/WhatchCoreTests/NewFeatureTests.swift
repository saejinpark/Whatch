import XCTest
@testable import WhatchCore

final class MorseCodeTests: XCTestCase {
    func testEncoding() {
        XCTAssertEqual(MorseCode.pattern(for: "SOS"), "... --- ...")
        XCTAssertEqual(MorseCode.pattern(for: "hi 5"), ".... ../.....")
        XCTAssertEqual(MorseCode.pattern(for: "  a   b "), ".-/-...")
    }

    func testUnknownCharactersAreSkipped() {
        XCTAssertEqual(MorseCode.pattern(for: "안녕 A!"), ".-")
        XCTAssertEqual(MorseCode.pattern(for: "???"), "")
    }

    func testSanitizing() {
        XCTAssertEqual(MorseCode.sanitized(".-x9/ .<script>"), ".-/ .")
        XCTAssertEqual(MorseCode.sanitized(String(repeating: ".", count: 500)).count, MorseCode.limit)
    }

    func testDisplay() {
        XCTAssertEqual(MorseCode.display(".- ."), "·— ·")
    }
}

final class BallGameTests: XCTestCase {
    func testNothingMovesBeforeTheStart() {
        var game = BallGame()
        game.step(dt: 0.1, tiltX: 1, tiltY: 1)
        XCTAssertEqual(game.x, 0.5)
        XCTAssertFalse(game.isRunning)
    }

    func testTiltRollsTheBall() {
        var game = BallGame()
        game.start()
        for _ in 0..<20 { game.step(dt: 0.02, tiltX: 0.5, tiltY: 0) }
        XCTAssertGreaterThan(game.x, 0.5)
        XCTAssertEqual(game.y, 0.5, accuracy: 1e-9)

        game.start()
        for _ in 0..<20 { game.step(dt: 0.02, tiltX: 0, tiltY: -0.5) }
        XCTAssertLessThan(game.y, 0.5)
    }

    func testBallStaysOnTheField() {
        var game = BallGame()
        game.start()
        for step in 0..<1200 {
            // Throw it into every wall in turn.
            let angle = Double(step / 150) * .pi / 2
            game.step(dt: 0.02, tiltX: cos(angle) * 5, tiltY: sin(angle) * 5)
            XCTAssertGreaterThanOrEqual(game.x, BallGame.ballRadius - 1e-9)
            XCTAssertLessThanOrEqual(game.x, 1 - BallGame.ballRadius + 1e-9)
            XCTAssertGreaterThanOrEqual(game.y, BallGame.ballRadius - 1e-9)
            XCTAssertLessThanOrEqual(game.y, 1 - BallGame.ballRadius + 1e-9)
        }
    }

    func testReachingTheTargetScoresAndMovesIt() {
        var game = BallGame()
        game.start()
        let firstTarget = (game.targetX, game.targetY)
        // Steer straight at the target like a player would.
        for _ in 0..<2000 where game.score == 0 {
            let dx = game.targetX - game.x, dy = game.targetY - game.y
            let length = max((dx * dx + dy * dy).squareRoot(), 1e-6)
            game.step(dt: 0.02, tiltX: dx / length * 0.6, tiltY: dy / length * 0.6)
        }
        XCTAssertEqual(game.score, 1)
        XCTAssertFalse(game.targetX == firstTarget.0 && game.targetY == firstTarget.1)
    }

    func testTheRoundEnds() {
        var game = BallGame()
        game.start()
        XCTAssertEqual(game.timeRemaining, BallGame.duration)
        for _ in 0..<Int(BallGame.duration / 0.05) + 5 { game.step(dt: 0.05, tiltX: 0, tiltY: 0) }
        XCTAssertFalse(game.isRunning)
        XCTAssertEqual(game.timeRemaining, 0)
    }

    func testSameSeedSameGame() {
        var first = BallGame(seed: 7), second = BallGame(seed: 7)
        first.start(); second.start()
        XCTAssertEqual(first, second)
        var other = BallGame(seed: 8)
        other.start()
        XCTAssertNotEqual(first.targetX, other.targetX)
    }
}

final class PointerMapperTests: XCTestCase {
    func testFirstReadingIsTheCentre() {
        var mapper = PointerMapper(range: 30)
        let point = mapper.point(yaw: 137, roll: -20)
        XCTAssertEqual(point.x, 0.5)
        XCTAssertEqual(point.y, 0.5)
    }

    func testSweepsReachTheEdges() {
        var mapper = PointerMapper(range: 30)
        _ = mapper.point(yaw: 0, roll: 0)
        XCTAssertEqual(mapper.point(yaw: 30, roll: 0).x, 0, accuracy: 1e-9)   // Left.
        XCTAssertEqual(mapper.point(yaw: -30, roll: 0).x, 1, accuracy: 1e-9)  // Right.
        XCTAssertEqual(mapper.point(yaw: 0, roll: 30).y, 0, accuracy: 1e-9)   // Up.
        XCTAssertEqual(mapper.point(yaw: 0, roll: -15).y, 0.75, accuracy: 1e-9)
        XCTAssertEqual(mapper.point(yaw: 90, roll: -90).x, 0)                  // Clamped.
    }

    func testWorksAcrossTheWrapAround() {
        var mapper = PointerMapper(range: 30)
        _ = mapper.point(yaw: 175, roll: 0)
        XCTAssertEqual(mapper.point(yaw: -170, roll: 0).x, 0.25, accuracy: 1e-9)
    }

    func testInvertAndRecenter() {
        var mapper = PointerMapper(range: 30, invertsVertical: true)
        _ = mapper.point(yaw: 0, roll: 0)
        XCTAssertEqual(mapper.point(yaw: 0, roll: 15).y, 0.75, accuracy: 1e-9)
        mapper.recenter()
        XCTAssertEqual(mapper.point(yaw: 50, roll: 15).x, 0.5)
    }
}

final class ReactionDuelTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 5_000)

    func testAFairRound() {
        var duel = ReactionDuel()
        duel.start(round: 7, delay: 2, now: start)
        XCTAssertEqual(duel.phase, .waiting)
        duel.tick(now: start.addingTimeInterval(1.9))
        XCTAssertEqual(duel.phase, .waiting)
        duel.tick(now: start.addingTimeInterval(2))
        XCTAssertEqual(duel.phase, .go)

        XCTAssertEqual(duel.tap(now: start.addingTimeInterval(2.25)), 250)
        XCTAssertEqual(duel.phase, .finished)
        XCTAssertNil(duel.outcome) // Still waiting for the other player.

        duel.receive(round: 7, milliseconds: 310)
        XCTAssertEqual(duel.outcome, .win)
        XCTAssertEqual(duel.wins, 1)
        XCTAssertEqual(duel.losses, 0)
    }

    func testTappingEarlyIsAFalseStart() {
        var duel = ReactionDuel()
        duel.start(round: 1, delay: 3, now: start)
        XCTAssertEqual(duel.tap(now: start.addingTimeInterval(1)), ReactionDuel.falseStart)
        duel.receive(round: 1, milliseconds: 900)
        XCTAssertEqual(duel.outcome, .lose)
        XCTAssertEqual(duel.losses, 1)
    }

    func testTheirResultCanArriveFirst() {
        var duel = ReactionDuel()
        duel.start(round: 3, delay: 1, now: start)
        duel.receive(round: 3, milliseconds: 200)
        XCTAssertNil(duel.outcome)
        XCTAssertEqual(duel.tap(now: start.addingTimeInterval(1.5)), 500)
        XCTAssertEqual(duel.outcome, .lose)
    }

    func testOutcomes() {
        func outcome(mine: Int, theirs: Int) -> ReactionDuel.Outcome? {
            var duel = ReactionDuel()
            duel.start(round: 1, delay: 0, now: start)
            if mine == ReactionDuel.falseStart {
                duel.start(round: 1, delay: 10, now: start)
                _ = duel.tap(now: start)
            } else {
                _ = duel.tap(now: start.addingTimeInterval(Double(mine) / 1000))
            }
            duel.receive(round: 1, milliseconds: theirs)
            return duel.outcome
        }
        XCTAssertEqual(outcome(mine: 300, theirs: 300), .draw)
        XCTAssertEqual(outcome(mine: 300, theirs: ReactionDuel.falseStart), .win)
        XCTAssertEqual(outcome(mine: ReactionDuel.falseStart, theirs: ReactionDuel.falseStart), .draw)
        XCTAssertEqual(outcome(mine: 301, theirs: 300), .lose)
    }

    func testStaleAndRepeatedResultsDoNotCount() {
        var duel = ReactionDuel()
        duel.receive(round: 9, milliseconds: 100) // Nothing started.
        XCTAssertNil(duel.theirTime)

        duel.start(round: 2, delay: 0, now: start)
        duel.receive(round: 1, milliseconds: 100) // An old round.
        XCTAssertNil(duel.theirTime)
        _ = duel.tap(now: start.addingTimeInterval(0.2))
        XCTAssertNil(duel.tap(now: start.addingTimeInterval(0.3))) // A second tap changes nothing.
        duel.receive(round: 2, milliseconds: 500)
        duel.receive(round: 2, milliseconds: 500)
        XCTAssertEqual(duel.wins, 1)

        duel.start(round: 3, delay: 0, now: start)
        XCTAssertNil(duel.myTime)
        XCTAssertEqual(duel.wins, 1) // The tally carries over.
    }
}

final class HeartRateHistoryTests: XCTestCase {
    func testStatistics() throws {
        var history = HeartRateHistory(baselineCount: 3)
        XCTAssertNil(history.current)
        for bpm in [60.0, 62, 64, 90] { history.add(bpm) }
        XCTAssertEqual(history.current, 90)
        XCTAssertEqual(history.minimum, 60)
        XCTAssertEqual(history.maximum, 90)
        XCTAssertEqual(try XCTUnwrap(history.average), 69, accuracy: 1e-9)
        XCTAssertEqual(history.baseline, 62)
        XCTAssertEqual(history.delta, 28)
    }

    func testNoBaselineUntilEnoughReadings() {
        var history = HeartRateHistory(baselineCount: 5)
        history.add(70)
        XCTAssertNil(history.baseline)
        XCTAssertNil(history.delta)
    }

    func testImpossibleReadingsAreIgnoredAndHistoryIsCapped() {
        var history = HeartRateHistory(limit: 10)
        for bpm in [0.0, -5, 400, .nan] { history.add(bpm) }
        XCTAssertTrue(history.samples.isEmpty)
        for bpm in 60..<100 { history.add(Double(bpm)) }
        XCTAssertEqual(history.samples.count, 10)
        XCTAssertEqual(history.current, 99)
        history.reset()
        XCTAssertTrue(history.samples.isEmpty)
        XCTAssertNil(history.baseline)
    }
}

final class HeightDifferenceTests: XCTestCase {
    func testStandardAtmosphere() {
        XCTAssertEqual(HeightDifference.altitude(forPressure: 101.325), 0, accuracy: 1e-6)
        // About 8.4 m per hPa near sea level.
        XCTAssertEqual(HeightDifference.altitude(forPressure: 101.225), 8.4, accuracy: 0.2)
    }

    func testLowerPressureMeansHigher() throws {
        var height = HeightDifference(smoothing: 1)
        XCTAssertNil(height.meters)
        height.updateLocal(101.300)
        height.updateRemote(101.288) // 0.12 hPa lower: about a metre up.
        XCTAssertEqual(try XCTUnwrap(height.meters), 1.0, accuracy: 0.05)
        height.updateRemote(101.312)
        XCTAssertLessThan(try XCTUnwrap(height.meters), 0)
    }

    func testCalibrationRemovesSensorDisagreement() throws {
        var height = HeightDifference(smoothing: 1)
        height.updateLocal(101.300)
        height.updateRemote(101.250) // Side by side, yet the sensors disagree by four metres.
        height.calibrate()
        XCTAssertEqual(try XCTUnwrap(height.meters), 0, accuracy: 1e-9)
        height.updateRemote(101.244) // Raise the other device half a metre.
        XCTAssertEqual(try XCTUnwrap(height.meters), 0.5, accuracy: 0.05)
    }

    func testSmoothingAndGlitches() throws {
        var height = HeightDifference(smoothing: 0.5)
        height.updateLocal(100)
        height.updateLocal(102)
        XCTAssertEqual(height.localPressure, 101)
        height.updateLocal(0)      // A glitch.
        height.updateLocal(.nan)
        XCTAssertEqual(height.localPressure, 101)
        height.updateRemote(101)
        height.clearRemote()
        XCTAssertNil(height.meters)
    }

    func testDistanceText() {
        XCTAssertEqual(DistanceFormat.text(meters: 0.384), "38 cm")
        XCTAssertEqual(DistanceFormat.text(meters: -0.12), "12 cm")
        XCTAssertEqual(DistanceFormat.text(meters: 0.999), "1.00 m")
        XCTAssertEqual(DistanceFormat.text(meters: 1.236), "1.24 m")
    }
}

final class LinkSyncTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testNothingIsSentUntilRequested() {
        var sync = LinkSync()
        XCTAssertNil(sync.begin(now: start))
        XCTAssertFalse(sync.isPending)
    }

    func testDeliveredAttemptSettlesTheRequest() throws {
        var sync = LinkSync()
        sync.request()
        let ticket = try XCTUnwrap(sync.begin(now: start))
        XCTAssertTrue(sync.finish(ticket, delivered: true))
        XCTAssertFalse(sync.isPending)
        XCTAssertNil(sync.begin(now: start.addingTimeInterval(10)))
    }

    func testFailedAttemptIsRetriedAtOnce() throws {
        var sync = LinkSync()
        sync.request()
        let first = try XCTUnwrap(sync.begin(now: start))
        XCTAssertFalse(sync.finish(first, delivered: false))
        XCTAssertTrue(sync.isPending)
        XCTAssertNotNil(sync.begin(now: start.addingTimeInterval(0.1)))
    }

    func testOnlyOneAttemptIsInFlightUntilItStalls() {
        var sync = LinkSync()
        sync.request()
        XCTAssertNotNil(sync.begin(now: start))
        XCTAssertNil(sync.begin(now: start.addingTimeInterval(1)))
        XCTAssertNotNil(sync.begin(now: start.addingTimeInterval(LinkSync.stallTimeout)))
    }

    func testAnOvertakenAttemptDoesNotSettleTheNewerRequest() throws {
        var sync = LinkSync()
        sync.request()
        let stale = try XCTUnwrap(sync.begin(now: start))
        sync.request()
        // A new request goes out immediately, without waiting for the old attempt.
        let fresh = try XCTUnwrap(sync.begin(now: start.addingTimeInterval(0.1)))
        XCTAssertFalse(sync.finish(stale, delivered: true))
        XCTAssertTrue(sync.isPending)
        XCTAssertTrue(sync.finish(fresh, delivered: true))
        XCTAssertFalse(sync.isPending)
    }

    func testALateAnswerAfterSettlingIsIgnored() throws {
        var sync = LinkSync()
        sync.request()
        let first = try XCTUnwrap(sync.begin(now: start))
        let second = try XCTUnwrap(sync.begin(now: start.addingTimeInterval(LinkSync.stallTimeout)))
        XCTAssertTrue(sync.finish(second, delivered: true))
        XCTAssertFalse(sync.finish(first, delivered: true))
    }
}

final class SteadyDistanceTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 2_000)

    /// Feeds one reading every `step` seconds, beginning `from` seconds after the start.
    private func feed(_ measure: inout SteadyDistance, _ values: [Double], from: TimeInterval, step: TimeInterval = 0.25) {
        for (index, value) in values.enumerated() {
            measure.add(value, now: start.addingTimeInterval(from + Double(index) * step))
        }
    }

    func testCountsDownWhileGettingIntoPosition() {
        var measure = SteadyDistance()
        XCTAssertFalse(measure.isRunning)
        measure.start(now: start)
        XCTAssertEqual(measure.phase, .preparing)
        XCTAssertEqual(measure.countdown(now: start), 3)
        XCTAssertEqual(measure.countdown(now: start.addingTimeInterval(1.2)), 2)
        XCTAssertEqual(measure.countdown(now: start.addingTimeInterval(2.9)), 1)
        measure.tick(now: start.addingTimeInterval(3))
        XCTAssertEqual(measure.phase, .measuring)
        XCTAssertEqual(measure.countdown(now: start.addingTimeInterval(3)), 0)
    }

    func testReadingsWhileGettingIntoPositionAreIgnored() {
        var measure = SteadyDistance()
        measure.start(now: start)
        feed(&measure, Array(repeating: 0.5, count: 10), from: 0)
        XCTAssertEqual(measure.phase, .preparing)
        // The arms are now out; only these readings may count.
        feed(&measure, Array(repeating: 1.6, count: 8), from: 3)
        XCTAssertEqual(measure.phase, .done(.init(meters: 1.6, isSteady: true)))
    }

    func testWaitsUntilTheReadingsSettle() {
        var measure = SteadyDistance()
        measure.start(now: start)
        feed(&measure, [0.9, 1.1, 1.3, 1.5, 1.6, 1.7], from: 3)
        XCTAssertEqual(measure.phase, .measuring)
        feed(&measure, [1.70, 1.72, 1.71, 1.70, 1.72, 1.71, 1.70, 1.71, 1.72], from: 4.5)
        guard case .done(let result) = measure.phase else { return XCTFail("still \(measure.phase)") }
        XCTAssertTrue(result.isSteady)
        XCTAssertEqual(result.meters, 1.71, accuracy: 0.011)
    }

    func testAFewQuickReadingsAreNotEnough() {
        var measure = SteadyDistance()
        measure.start(now: start)
        // Identical, but they cover only half a second.
        feed(&measure, [1.5, 1.5, 1.5], from: 3)
        XCTAssertEqual(measure.phase, .measuring)
    }

    func testOneStrayReadingDoesNotMoveTheResult() {
        var measure = SteadyDistance()
        measure.start(now: start)
        feed(&measure, [1.50, 1.51, 1.50, 1.55, 1.50, 1.51, 1.50, 1.50], from: 3)
        guard case .done(let result) = measure.phase else { return XCTFail("still \(measure.phase)") }
        XCTAssertEqual(result.meters, 1.5, accuracy: 0.011)
    }

    func testAnswersRoughlyWhenTheReadingsNeverSettle() {
        var measure = SteadyDistance()
        measure.start(now: start)
        let wobbling = (0..<60).map { 1.5 + ($0.isMultiple(of: 2) ? 0.1 : -0.1) }
        feed(&measure, wobbling, from: 3)
        guard case .done(let result) = measure.phase else { return XCTFail("still \(measure.phase)") }
        XCTAssertFalse(result.isSteady)
        XCTAssertEqual(result.meters, 1.5, accuracy: 0.11)
        XCTAssertFalse(measure.isRunning)
    }

    func testFailsWhenNoReadingArrives() {
        var measure = SteadyDistance()
        measure.start(now: start)
        measure.tick(now: start.addingTimeInterval(5))
        XCTAssertEqual(measure.phase, .measuring)
        measure.tick(now: start.addingTimeInterval(SteadyDistance.preparation + SteadyDistance.timeout))
        XCTAssertEqual(measure.phase, .failed)
    }

    func testResetAndStartAgain() {
        var measure = SteadyDistance()
        measure.start(now: start)
        feed(&measure, Array(repeating: 2.0, count: 8), from: 3)
        measure.reset()
        XCTAssertEqual(measure.phase, .idle)
        let later = start.addingTimeInterval(60)
        measure.start(now: later)
        XCTAssertEqual(measure.countdown(now: later), 3)
        measure.tick(now: later.addingTimeInterval(4))
        // Nothing from the first run may leak into the second.
        XCTAssertEqual(measure.phase, .measuring)
    }
}

final class ArmSpanTests: XCTestCase {
    func testDefaultOffsetCoversTheHands() {
        XCTAssertEqual(ArmSpan.height(distance: 1.45, offset: ArmSpan.defaultOffset), 1.72, accuracy: 1e-9)
    }

    func testCalibrationReproducesTheKnownHeight() throws {
        let offset = try XCTUnwrap(ArmSpan.offset(height: 1.80, distance: 1.49))
        XCTAssertEqual(ArmSpan.height(distance: 1.49, offset: offset), 1.80, accuracy: 1e-9)
        // Someone else measured with the same calibration.
        XCTAssertEqual(ArmSpan.height(distance: 1.35, offset: offset), 1.66, accuracy: 1e-9)
    }

    func testImplausibleCalibrationIsRefused() {
        // The arms were not out, or the height was mistyped.
        XCTAssertNil(ArmSpan.offset(height: 1.75, distance: 0.6))
        XCTAssertNil(ArmSpan.offset(height: 1.20, distance: 1.6))
    }

    func testHeightIsShownInWholeCentimetres() {
        XCTAssertEqual(DistanceFormat.height(meters: 1.724), "172 cm")
        XCTAssertEqual(DistanceFormat.height(meters: 0.98), "98 cm")
    }

    func testCalibrationTravelsWithTheState() throws {
        let sent = DeviceState(timestamp: 3, armSpanOffset: 0.31)
        let received = try XCTUnwrap(DeviceState(payload: sent.payload))
        XCTAssertEqual(try XCTUnwrap(received.armSpanOffset), 0.31, accuracy: 1e-9)
        XCTAssertNil(DeviceState(payload: DeviceState(timestamp: 3).payload)?.armSpanOffset)
    }
}
