//
//  VibrationScreen.swift
//  Whatch Watch App
//

import SwiftUI

@MainActor
@Observable
final class VibrationModel {
    private(set) var analyzer = VibrationAnalyzer()

    @ObservationIgnored private let feed = MotionFeed()

    func start() {
        feed.start { [weak self] sample in
            self?.analyzer.add(x: sample.x, y: sample.y, z: sample.z)
        }
    }

    func stop() {
        feed.stop()
    }

    func reset() {
        analyzer.reset()
    }
}

struct VibrationScreen: View {
    @State private var model = VibrationModel()

    /// Change in acceleration that reaches the top of the chart.
    private static let fullScale = 1.5

    var body: some View {
        let analyzer = model.analyzer
        let level = analyzer.level

        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack(spacing: 6) {
                Circle()
                    .fill(level.tint)
                    .frame(width: 10, height: 10)
                Text(level.title)
                    .font(.headline)
                    .foregroundStyle(level.tint)
                Spacer()
                Text(analyzer.intensity, format: .number.precision(.fractionLength(2)))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                Text("G")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Sparkline(values: analyzer.samples, tint: level.tint, range: 0...Self.fullScale)
                .frame(maxHeight: .infinity)
                .padding(6)
                .background(Color.card, in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))

            HStack {
                Text("최대 \(analyzer.peak.formatted(.number.precision(.fractionLength(2)))) G")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("초기화", systemImage: "arrow.counterclockwise") {
                    model.reset()
                }
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

#Preview {
    NavigationStack {
        VibrationScreen()
    }
}
