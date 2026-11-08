//
//  BoardScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// Colours of the Watch Board. Index zero is the eraser. Order is persisted, so only append.
enum BoardPalette {
    static let colors: [Color] = [.clear, .white, .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]

    static func color(_ index: UInt8) -> Color {
        colors.indices.contains(Int(index)) ? colors[Int(index)] : .clear
    }
}

/// Which way the Digital Crown moves the cursor.
enum BoardAxis {
    case horizontal
    case vertical
}

/// The drawing, the cursor and the pen, saved after every stroke.
@MainActor
@Observable
final class BoardStore {
    private(set) var board: Board
    private(set) var cursorRow = 0
    private(set) var cursorColumn = 0
    var colorIndex: UInt8 = 1
    var axis: BoardAxis = .horizontal
    var isPenDown = false {
        didSet { if isPenDown { paintCursor() } }
    }

    @ObservationIgnored private var lastTouch: (row: Int, column: Int)?
    private static let storageKey = "watchBoard.v2"

    init() {
        board = UserDefaults.standard.data(forKey: Self.storageKey).flatMap(Board.init(data:)) ?? Board()
    }

    /// Position of the cursor along the active axis.
    var cursorPosition: Int {
        axis == .horizontal ? cursorColumn : cursorRow
    }

    var axisLimit: Int {
        axis == .horizontal ? board.columns : board.rows
    }

    /// Finger drawing: paint from the previous touch position to this one and move the cursor there.
    func touch(at point: CGPoint, cellSize: CGFloat) {
        guard let cell = board.cell(at: point, cellSize: cellSize) else { return }
        let stroke = lastTouch.map { Board.line(from: $0, to: cell) } ?? [cell]
        var changed = false
        for step in stroke {
            changed = board.paint(row: step.row, column: step.column, color: colorIndex) || changed
        }
        lastTouch = cell
        cursorRow = cell.row
        cursorColumn = cell.column
        if changed { save() }
    }

    /// Call when the finger lifts, so the next stroke does not connect to this one.
    func endTouch() {
        lastTouch = nil
    }

    /// Crown drawing: move along the active axis, painting if the pen is down.
    func moveCursor(to position: Int) {
        let clamped = min(max(position, 0), axisLimit - 1)
        guard clamped != cursorPosition else { return }
        if axis == .horizontal {
            cursorColumn = clamped
        } else {
            cursorRow = clamped
        }
        if isPenDown { paintCursor() }
    }

    func clear() {
        board.clear()
        save()
    }

    private func paintCursor() {
        if board.paint(row: cursorRow, column: cursorColumn, color: colorIndex) {
            save()
        }
    }

    private func save() {
        UserDefaults.standard.set(board.data, forKey: Self.storageKey)
    }
}

/// A pixel canvas: draw with a finger, or steer the cursor with the Digital Crown.
struct BoardScreen: View {
    @State private var store = BoardStore()
    @State private var crown = 0.0
    @State private var isPalettePresented = false
    @State private var isClearConfirmationPresented = false

    var body: some View {
        GeometryReader { proxy in
            let cell = min(proxy.size.width / CGFloat(store.board.columns),
                           proxy.size.height / CGFloat(store.board.rows))
            let size = CGSize(width: cell * CGFloat(store.board.columns),
                              height: cell * CGFloat(store.board.rows))

            canvas(cell: cell)
                .frame(width: size.width, height: size.height)
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { store.touch(at: $0.location, cellSize: cell) }
                        .onEnded { _ in store.endTouch() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .digitalCrownRotation(
            $crown,
            from: 0,
            through: Double(store.axisLimit - 1),
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crown) { _, value in
            store.moveCursor(to: Int(value.rounded()))
        }
        .onChange(of: store.cursorPosition, initial: true) { _, position in
            // Keep the crown in step after a touch or an axis switch.
            if Int(crown.rounded()) != position {
                crown = Double(position)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("지우기", systemImage: "trash") {
                    isClearConfirmationPresented = true
                }
                .disabled(store.board.isEmpty)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    store.axis = store.axis == .horizontal ? .vertical : .horizontal
                } label: {
                    Image(systemName: store.axis == .horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
                }
                .accessibilityLabel(store.axis == .horizontal ? "크라운: 가로 이동" : "크라운: 세로 이동")

                Button {
                    isPalettePresented = true
                } label: {
                    swatch(store.colorIndex)
                        .frame(width: 22, height: 22)
                }
                .accessibilityLabel("색상 선택")

                Button {
                    store.isPenDown.toggle()
                } label: {
                    Image(systemName: store.isPenDown ? "pencil.tip" : "pencil.slash")
                }
                .tint(store.isPenDown ? Feature.board.tint : nil)
                .accessibilityLabel(store.isPenDown ? "펜 내림" : "펜 올림")
            }
        }
        .sheet(isPresented: $isPalettePresented) {
            palette
        }
        .confirmationDialog("그림을 모두 지울까요?", isPresented: $isClearConfirmationPresented) {
            Button("지우기", role: .destructive) {
                store.clear()
            }
        }
    }

    private func canvas(cell: CGFloat) -> some View {
        Canvas { context, _ in
            let board = store.board
            for row in 0..<board.rows {
                for column in 0..<board.columns {
                    let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    let index = board.color(row: row, column: column)
                    if index != 0 {
                        context.fill(Path(rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(BoardPalette.color(index)))
                    } else {
                        // A faint dot marks each empty cell.
                        let dot = CGRect(x: rect.midX - 0.75, y: rect.midY - 0.75, width: 1.5, height: 1.5)
                        context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.2)))
                    }
                }
            }
            let cursor = CGRect(x: CGFloat(store.cursorColumn) * cell, y: CGFloat(store.cursorRow) * cell,
                                width: cell, height: cell).insetBy(dx: 1, dy: 1)
            context.stroke(Path(roundedRect: cursor, cornerRadius: 2), with: .color(.white), lineWidth: 1.5)
        }
        .accessibilityLabel("그림판")
    }

    private func swatch(_ index: UInt8) -> some View {
        ZStack {
            Circle()
                .fill(BoardPalette.color(index))
            Circle()
                .strokeBorder(.white.opacity(0.6), lineWidth: 1)
            if index == 0 {
                Image(systemName: "eraser.fill")
                    .font(.system(size: 11))
            }
        }
    }

    private var palette: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(BoardPalette.colors.indices, id: \.self) { index in
                    Button {
                        store.colorIndex = UInt8(index)
                        isPalettePresented = false
                    } label: {
                        swatch(UInt8(index))
                            .frame(width: 34, height: 34)
                            .overlay {
                                if store.colorIndex == UInt8(index) {
                                    Circle().strokeBorder(Feature.board.tint, lineWidth: 3)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(index == 0 ? "지우개" : "색상 \(index)")
                }
            }
            .padding(.top, 4)
        }
        .navigationTitle("색상")
    }
}

#Preview {
    NavigationStack {
        BoardScreen()
    }
}
