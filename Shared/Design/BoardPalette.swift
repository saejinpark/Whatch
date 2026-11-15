//
//  BoardPalette.swift
//  Whatch
//

import SwiftUI

/// Colours of the Watch Board. Index zero is the eraser. Order is persisted, so only append.
enum BoardPalette {
    static let colors: [Color] = [.clear, .white, .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]

    static func color(_ index: UInt8) -> Color {
        colors.indices.contains(Int(index)) ? colors[Int(index)] : .clear
    }
}

/// The Watch Board drawn at any size, without a cursor.
struct BoardCanvas: View {
    let board: Board

    var body: some View {
        Canvas { context, size in
            let cell = min(size.width / CGFloat(board.columns), size.height / CGFloat(board.rows))
            for row in 0..<board.rows {
                for column in 0..<board.columns {
                    let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    let index = board.color(row: row, column: column)
                    if index != 0 {
                        context.fill(Path(rect.insetBy(dx: cell * 0.03, dy: cell * 0.03)),
                                     with: .color(BoardPalette.color(index)))
                    } else {
                        let dot = CGRect(x: rect.midX - cell * 0.05, y: rect.midY - cell * 0.05,
                                         width: cell * 0.1, height: cell * 0.1)
                        context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.2)))
                    }
                }
            }
        }
        .aspectRatio(CGFloat(board.columns) / CGFloat(board.rows), contentMode: .fit)
        .background(Color.black)
    }
}
