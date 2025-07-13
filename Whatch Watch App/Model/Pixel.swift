//
//  Cell.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI
import SwiftData

@Model
class Pixel {
    @Attribute(.unique) var id: Int
    var row: Int
    var column: Int
    var boardColorRawValue: String

    var boardColor: BoardColor {
        get { BoardColor(rawValue: boardColorRawValue) ?? .gray1 }
        set { boardColorRawValue = newValue.rawValue }
    }

    var color: Color {
        boardColor.color
    }

    init(row: Int, column: Int, color: BoardColor, columnLimit: Int) {
        self.id = row * columnLimit + column
        self.row = row
        self.column = column
        self.boardColorRawValue = color.rawValue
    }
}

