import XCTest
@testable import WhatchCore

final class BoardTests: XCTestCase {
    func testPaintAndRead() {
        var board = Board(columns: 4, rows: 3)
        XCTAssertTrue(board.isEmpty)
        XCTAssertTrue(board.paint(row: 2, column: 3, color: 5))
        XCTAssertEqual(board.color(row: 2, column: 3), 5)
        XCTAssertFalse(board.isEmpty)
        // Painting the same colour again is not a change.
        XCTAssertFalse(board.paint(row: 2, column: 3, color: 5))
    }

    func testOutOfBoundsIsIgnored() {
        var board = Board(columns: 4, rows: 3)
        XCTAssertFalse(board.paint(row: 3, column: 0, color: 1))
        XCTAssertFalse(board.paint(row: 0, column: -1, color: 1))
        XCTAssertEqual(board.color(row: 99, column: 99), 0)
        XCTAssertTrue(board.isEmpty)
    }

    func testHitTesting() {
        let board = Board(columns: 4, rows: 3)
        let hit = board.cell(at: CGPoint(x: 25, y: 12), cellSize: 10)
        XCTAssertEqual(hit?.row, 1)
        XCTAssertEqual(hit?.column, 2)
        XCTAssertNil(board.cell(at: CGPoint(x: 40, y: 0), cellSize: 10))
        XCTAssertNil(board.cell(at: CGPoint(x: -1, y: 5), cellSize: 10))
        XCTAssertNil(board.cell(at: CGPoint(x: 5, y: 5), cellSize: 0))
    }

    func testDataRoundTrip() throws {
        var board = Board()
        board.paint(row: 0, column: 0, color: 1)
        board.paint(row: 7, column: 11, color: 9)
        let restored = try XCTUnwrap(Board(data: board.data))
        XCTAssertEqual(restored, board)
    }

    func testCorruptDataIsRejected() {
        XCTAssertNil(Board(data: Data()))
        XCTAssertNil(Board(data: Data([12, 8, 0, 0])))
        XCTAssertNil(Board(data: Data([0, 0])))
    }

    func testLineConnectsTwoCellsWithoutGaps() {
        let ends: [((Int, Int), (Int, Int))] = [((0, 0), (0, 5)), ((0, 0), (7, 0)), ((1, 1), (6, 10)),
                                                ((7, 11), (0, 0)), ((3, 3), (3, 3)), ((5, 2), (1, 9))]
        for (start, end) in ends {
            let cells = Board.line(from: start, to: end)
            XCTAssertEqual(cells.first?.row, start.0)
            XCTAssertEqual(cells.first?.column, start.1)
            XCTAssertEqual(cells.last?.row, end.0)
            XCTAssertEqual(cells.last?.column, end.1)
            // Consecutive cells always touch, so the stroke has no holes.
            for (a, b) in zip(cells, cells.dropFirst()) {
                XCTAssertLessThanOrEqual(abs(a.row - b.row), 1)
                XCTAssertLessThanOrEqual(abs(a.column - b.column), 1)
            }
            XCTAssertEqual(cells.count, max(abs(end.0 - start.0), abs(end.1 - start.1)) + 1)
        }
    }

    func testClear() {
        var board = Board()
        board.paint(row: 1, column: 1, color: 3)
        board.clear()
        XCTAssertTrue(board.isEmpty)
    }
}
