//
//  WatchBoardContentView.swift
//  Whatch Watch App
//

import SwiftData
import SwiftUI

/// Pixel canvas driven by the Digital Crown: one axis at a time, switched from the toolbar.
struct WatchBoardContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pixel.id) private var savedPixels: [Pixel]
    @State private var board = WatchBoardModel()
    @FocusState private var focusedAxis: BoardAxis?

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Color.clear
                .onChange(of: size, initial: true) {
                    guard !board.isConfigured, size.width > 0, size.height > 0 else { return }
                    board.configure(width: Int(size.width), height: Int(size.height),
                                    context: context, existingPixels: savedPixels)
                    Task { @MainActor in focusedAxis = .row }
                }

            grid

            crownReceiver(for: .row, limit: board.rowLimit) { board.row = $0 }
            crownReceiver(for: .column, limit: board.columnLimit) { board.column = $0 }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                toolbarContent
            }
        }
    }

    private var grid: some View {
        let cell = CGFloat(board.unit)
        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cell), spacing: 0), count: board.columnLimit),
            spacing: 0
        ) {
            ForEach(board.pixels, id: \.id) { pixel in
                Rectangle()
                    .fill(pixel.color)
                    .frame(width: cell, height: cell)
                    .overlay {
                        if board.row == pixel.row && board.column == pixel.column {
                            Image(systemName: "plus")
                        }
                    }
            }
        }
    }

    /// Invisible focus target that routes Digital Crown rotation to one axis of the cursor.
    private func crownReceiver(for axis: BoardAxis, limit: Int, update: @escaping (Int) -> Void) -> some View {
        let value = Binding<Double>(
            get: { Double(axis == .row ? board.row : board.column) },
            set: {
                update(Int($0))
                board.paintIfPenDown(context: context)
            }
        )
        return Rectangle()
            .frame(width: 1, height: 1)
            .opacity(0)
            .focusable(true)
            .focused($focusedAxis, equals: axis)
            .digitalCrownRotation(
                value,
                from: 0,
                through: Double(max(limit - 1, 0)),
                by: 1,
                sensitivity: .low
            )
    }

    private var toolbarContent: some View {
        HStack {
            Button {
                focusedAxis = focusedAxis == .row ? .column : .row
            } label: {
                Label("축 전환", systemImage: focusedAxis == .row
                      ? "digitalcrown.arrow.clockwise.fill"
                      : "digitalcrown.horizontal.arrow.counterclockwise.fill")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(focusedAxis == .row ? "세로 축" : "가로 축")
            }

            Spacer()

            Button {
                board.cycleColor(context: context)
            } label: {
                Circle().fill(board.selectedColor.color)
            }
            .accessibilityLabel("색상 변경")

            Spacer()

            Button {
                board.togglePen(context: context)
            } label: {
                Label("펜 상태", systemImage: board.isPenDown ? "pencil" : "pencil.slash")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(board.isPenDown ? "펜 내림" : "펜 올림")
            }
            .tint(board.isPenDown ? .gray : nil)
        }
    }
}

#Preview {
    NavigationStack {
        WatchBoardContentView()
    }
    .modelContainer(for: Pixel.self, inMemory: true)
}
