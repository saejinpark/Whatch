//
//  Board.swift
//  Whatch
//

import CoreGraphics
import Foundation

/// The pixel canvas of the Watch Board: a fixed grid of palette indices.
struct Board: Equatable, Sendable {
    static let defaultColumns = 12
    static let defaultRows = 8

    let columns: Int
    let rows: Int
    /// Palette index per cell, row by row. Zero is empty.
    private(set) var cells: [UInt8]

    init(columns: Int = Board.defaultColumns, rows: Int = Board.defaultRows) {
        self.columns = max(columns, 1)
        self.rows = max(rows, 1)
        cells = Array(repeating: 0, count: self.columns * self.rows)
    }

    var isEmpty: Bool {
        cells.allSatisfy { $0 == 0 }
    }

    func contains(row: Int, column: Int) -> Bool {
        (0..<rows).contains(row) && (0..<columns).contains(column)
    }

    func color(row: Int, column: Int) -> UInt8 {
        contains(row: row, column: column) ? cells[row * columns + column] : 0
    }

    /// Paints one cell. Returns `true` when the board changed.
    @discardableResult
    mutating func paint(row: Int, column: Int, color: UInt8) -> Bool {
        guard contains(row: row, column: column) else { return false }
        let index = row * columns + column
        guard cells[index] != color else { return false }
        cells[index] = color
        return true
    }

    mutating func clear() {
        cells = Array(repeating: 0, count: columns * rows)
    }

    /// The cell under a point, for a board drawn from the origin with square cells.
    func cell(at point: CGPoint, cellSize: CGFloat) -> (row: Int, column: Int)? {
        guard cellSize > 0, point.x >= 0, point.y >= 0 else { return nil }
        let row = Int(point.y / cellSize)
        let column = Int(point.x / cellSize)
        return contains(row: row, column: column) ? (row, column) : nil
    }

    /// The cells on a straight line between two cells, both included.
    ///
    /// A fast finger reports only a few positions, so strokes are drawn by connecting them.
    static func line(from start: (row: Int, column: Int), to end: (row: Int, column: Int)) -> [(row: Int, column: Int)] {
        var cells: [(row: Int, column: Int)] = []
        var row = start.row
        var column = start.column
        let deltaRow = abs(end.row - start.row)
        let deltaColumn = abs(end.column - start.column)
        let stepRow = start.row < end.row ? 1 : -1
        let stepColumn = start.column < end.column ? 1 : -1
        var error = deltaColumn - deltaRow

        while true {
            cells.append((row, column))
            if row == end.row && column == end.column { break }
            let doubled = 2 * error
            if doubled > -deltaRow {
                error -= deltaRow
                column += stepColumn
            }
            if doubled < deltaColumn {
                error += deltaColumn
                row += stepRow
            }
        }
        return cells
    }

    // MARK: Persistence

    /// Two header bytes (columns, rows) followed by one byte per cell.
    var data: Data {
        Data([UInt8(clamping: columns), UInt8(clamping: rows)] + cells)
    }

    init?(data: Data) {
        guard data.count >= 2 else { return nil }
        let columns = Int(data[data.startIndex])
        let rows = Int(data[data.startIndex + 1])
        guard columns > 0, rows > 0, data.count == 2 + columns * rows else { return nil }
        self.columns = columns
        self.rows = rows
        cells = Array(data.dropFirst(2))
    }
}
