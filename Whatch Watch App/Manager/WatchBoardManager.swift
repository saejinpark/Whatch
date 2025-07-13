//
//  WatchBoardManager.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI
import SwiftData

@MainActor
class WatchBoardManager: ObservableObject {
    @Published var pixels: [Pixel] = []
    @Published var row: Int = 0
    @Published var column: Int = 0

    @Published var unit: Int = 0
    @Published var rowLimit: Int = 0
    @Published var columnLimit: Int = 0

    @Published var selectedColor: BoardColor = .gray6
    @Published var isPenDown: Bool = false

    /// 초기 바둑판 구성
    func setupGrid(width: Int, height: Int, context: ModelContext, existingPixels: [Pixel]) {

        let gcd = Self.greatestCommonDivisor(width, height)
        self.unit = max(gcd, 10)
        self.rowLimit = max(Int(height / unit) - 3, 1)
        self.columnLimit = max(width / unit, 1)


        guard existingPixels.isEmpty else {
            self.pixels = existingPixels
            return
        }
        
        for row in 0..<rowLimit {
            for column in 0..<columnLimit {
                let pixel = Pixel(row: row, column: column, color: .clear, columnLimit: columnLimit)
                context.insert(pixel)
                pixels.append(pixel)
            }
        }

        try? context.save()
    }

    /// 위치가 바뀌었을 때 호출: 펜이 내려가 있으면 색칠
    func applyIfNeeded(context: ModelContext) {
        guard isPenDown else { return }
        toggleColor(atRow: row, column: column, context: context)
    }

    /// 특정 좌표 색깔 변경
    func toggleColor(atRow row: Int, column: Int, context: ModelContext) {
        guard let index = pixels.firstIndex(where: { $0.row == row && $0.column == column }) else { return }

        pixels[index].boardColor = selectedColor
        try? context.save()
    }
    
    func setColor(_ color: BoardColor, context: ModelContext) {
        selectedColor = color
        if isPenDown {
            toggleColor(atRow: row, column: column, context: context)
        }
    }
    
    func setPenDown(_ down: Bool, context: ModelContext) {
        isPenDown = down
        if down {
            // 펜을 내리자마자 현재 위치 색칠
            toggleColor(atRow: row, column: column, context: context)
        }
    }

    /// GCD 계산기 (unit 크기 설정용)
    static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = abs(a)
        var b = abs(b)
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }
}
