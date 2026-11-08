import XCTest
@testable import WhatchCore

final class PingTrackerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testAnsweredPingRecordsLatency() throws {
        var tracker = PingTracker()
        let sentAt = try XCTUnwrap(tracker.tick(now: start, isReachable: true))
        XCTAssertEqual(tracker.status, .waiting)

        XCTAssertTrue(tracker.receivePong(sentAt: sentAt, now: start.addingTimeInterval(0.25)))
        XCTAssertEqual(tracker.status, .connected)
        XCTAssertEqual(try XCTUnwrap(tracker.latency), 0.25, accuracy: 1e-6)
        XCTAssertEqual(tracker.samples.count, 1)
        XCTAssertEqual(tracker.lastSentAt, start)
    }

    func testOnlyOnePingIsInFlight() throws {
        var tracker = PingTracker(timeout: 3)
        XCTAssertNotNil(tracker.tick(now: start, isReachable: true))
        XCTAssertNil(tracker.tick(now: start.addingTimeInterval(1), isReachable: true))
        XCTAssertNil(tracker.tick(now: start.addingTimeInterval(2), isReachable: true))
        XCTAssertEqual(tracker.sentCount, 1)
    }

    func testTimeoutCountsAsLostAndSendsAgain() throws {
        var tracker = PingTracker(timeout: 3)
        let first = try XCTUnwrap(tracker.tick(now: start, isReachable: true))
        let second = try XCTUnwrap(tracker.tick(now: start.addingTimeInterval(3), isReachable: true))
        XCTAssertEqual(tracker.status, .lost)
        XCTAssertEqual(tracker.lostCount, 1)

        // The late answer to the first ping is ignored…
        XCTAssertFalse(tracker.receivePong(sentAt: first, now: start.addingTimeInterval(3.1)))
        XCTAssertEqual(tracker.status, .lost)
        // …but the answer to the second one counts.
        XCTAssertTrue(tracker.receivePong(sentAt: second, now: start.addingTimeInterval(3.2)))
        XCTAssertEqual(tracker.status, .connected)
    }

    func testUnreachableIsLostWithoutSending() {
        var tracker = PingTracker()
        XCTAssertNil(tracker.tick(now: start, isReachable: false))
        XCTAssertEqual(tracker.status, .lost)
        XCTAssertEqual(tracker.sentCount, 0)
    }

    func testStatisticsAndSampleLimit() throws {
        var tracker = PingTracker(sampleLimit: 3)
        var now = start
        for latency in [0.1, 0.2, 0.3, 0.4] {
            let sentAt = try XCTUnwrap(tracker.tick(now: now, isReachable: true))
            tracker.receivePong(sentAt: sentAt, now: now.addingTimeInterval(latency))
            now.addTimeInterval(1)
        }
        XCTAssertEqual(tracker.samples.count, 3)
        XCTAssertEqual(try XCTUnwrap(tracker.minimum), 0.2, accuracy: 1e-6)
        XCTAssertEqual(try XCTUnwrap(tracker.maximum), 0.4, accuracy: 1e-6)
        XCTAssertEqual(try XCTUnwrap(tracker.average), 0.3, accuracy: 1e-6)
    }

    func testResetClearsEverything() throws {
        var tracker = PingTracker()
        let sentAt = try XCTUnwrap(tracker.tick(now: start, isReachable: true))
        tracker.receivePong(sentAt: sentAt, now: start.addingTimeInterval(0.1))
        tracker.reset()
        XCTAssertEqual(tracker, PingTracker())
    }
}
