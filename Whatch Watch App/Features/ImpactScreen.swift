//
//  ImpactScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// Runs an `ImpactMeter` off the motion feed and remembers the best swing.
@MainActor
@Observable
final class ImpactModel {
    private(set) var meter: ImpactMeter

    @ObservationIgnored private let feed = MotionFeed()
    private static let peakKey = "impactPeak"

    init() {
        meter = ImpactMeter(peak: UserDefaults.standard.double(forKey: Self.peakKey))
    }

    func start() {
        feed.start { [weak self] sample in
            guard let self else { return }
            let previousPeak = meter.peak
            meter.add(x: sample.x, y: sample.y, z: sample.z, at: Date())
            if meter.peak != previousPeak {
                UserDefaults.standard.set(meter.peak, forKey: Self.peakKey)
            }
        }
    }

    func stop() {
        feed.stop()
    }

    func reset() {
        meter.reset()
        UserDefaults.standard.set(0.0, forKey: Self.peakKey)
    }
}

struct ImpactScreen: View {
    @State private var model = ImpactModel()

    /// Acceleration that fills the ring.
    private static let fullScale = 6.0

    var body: some View {
        let meter = model.meter

        VStack(spacing: Layout.spacing) {
            RingGauge(value: meter.current / Self.fullScale, tint: Feature.impact.tint) {
                VStack(spacing: -2) {
                    Text(meter.current, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("G")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("≈ \(meter.equivalentMass.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.caption2)
                        .foregroundStyle(Feature.impact.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, Layout.ringWidth)
            }

            HStack(spacing: Layout.spacing) {
                StatTile(title: "최고", value: meter.peak.formatted(.number.precision(.fractionLength(2))) + " G",
                         tint: Feature.impact.tint)
                StatTile(title: "횟수", value: "\(meter.count)")
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
        ImpactScreen()
    }
}
