//
//  WatchBoardModel.swift
//  Whatch Watch App
//

import Foundation
import SwiftData

/// Grid geometry, cursor and pen state of the Watch Board.
@MainActor
@Observable
final class WatchBoardModel {
    private(set) var pixels: [Pixel] = []
    var row = 0
    var column = 0

    /// Side length of one cell in points. Zero until `configure` has run.
    private(set) var unit = 0
    private(set) var rowLimit = 0
    private(set) var columnLimit = 0

    private(set) var selectedColor: BoardColor = .gray6
    private(set) var isPenDown = false

    private static let minimumUnit = 10
    /// Rows left free at the bottom so the toolbar does not cover the board.
    private static let reservedRows = 3

    var isConfigured: Bool {
        unit > 0
    }

    /// Builds the grid for the given size, reusing persisted pixels when there are any.
    func configure(width: Int, height: Int, context: ModelContext, existingPixels: [Pixel]) {
        unit = max(Self.greatestCommonDivisor(width, height), Self.minimumUnit)
        rowLimit = max(height / unit - Self.reservedRows, 1)
        columnLimit = max(width / unit, 1)

        guard existingPixels.isEmpty else {
            pixels = existingPixels
            return
        }

        pixels = (0..<rowLimit).flatMap { row in
            (0..<columnLimit).map { column in
                Pixel(row: row, column: column, color: .clear, columnLimit: columnLimit)
            }
        }
        pixels.forEach(context.insert)
        save(context)
    }

    /// Call after the cursor moved: paints the new cell when the pen is down.
    func paintIfPenDown(context: ModelContext) {
        guard isPenDown else { return }
        paintCurrentCell(context: context)
    }

    func cycleColor(context: ModelContext) {
        selectedColor = selectedColor.next
        paintIfPenDown(context: context)
    }

    func togglePen(context: ModelContext) {
        isPenDown.toggle()
        paintIfPenDown(context: context)
    }

    private func paintCurrentCell(context: ModelContext) {
        guard let pixel = pixels.first(where: { $0.row == row && $0.column == column }) else { return }
        pixel.boardColor = selectedColor
        save(context)
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            Log.features.error("Watch Board save failed: \(error.localizedDescription)")
        }
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = abs(a)
        var b = abs(b)
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return a
    }
}
