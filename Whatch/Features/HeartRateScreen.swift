//
//  HeartRateScreen.swift
//  Whatch
//

import SwiftUI

/// The Watch's heart rate, live on the big screen.
struct HeartRateScreen: View {
    @Environment(AppModel.self) private var model

    private let tint = Feature.heartRate.tint

    var body: some View {
        let heart = model.heart
        let isLive = model.isHeartLive

        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(isLive ? tint : .secondary)
                        .symbolEffect(.pulse, isActive: isLive)
                    Text(heart.current.map { "\(Int($0.rounded()))" } ?? "--")
                        .font(.system(size: Layout.heroFont, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: heart.current)
                    Text("BPM")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                if let delta = heart.delta {
                    Pill(text: deltaText(delta), tint: abs(delta) >= 10 ? tint : .secondary)
                }
                if heart.samples.count > 1 {
                    Sparkline(values: heart.samples, tint: tint, range: chartRange(heart))
                        .frame(height: Layout.chartHeight)
                        .padding(.top, 8)
                }
            }
            .card()
            .accessibilityElement(children: .combine)

            HStack(spacing: 12) {
                StatTile(title: "최저", value: text(heart.minimum))
                StatTile(title: "평균", value: text(heart.average))
                StatTile(title: "최고", value: text(heart.maximum))
            }

            if !isLive {
                VStack(spacing: 8) {
                    Label("워치에서 심박 중계를 시작해 주세요", systemImage: "applewatch")
                        .font(.subheadline.weight(.medium))
                    Text("워치의 Whatch에서 심박 중계 화면이 열려요. 측정값은 두 기기 사이에서만 오가고 저장되지 않아요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    LinkAdvice(text: model.link.advice)
                }
                .card()
            }
        }
        .opensOnCounterpart(.heartRate, model: model)
    }

    private func text(_ value: Double?) -> String {
        value.map { "\(Int($0.rounded()))" } ?? "--"
    }

    private func deltaText(_ delta: Double) -> String {
        let rounded = Int(delta.rounded())
        if rounded == 0 { return "처음과 같아요" }
        return "처음보다 \(rounded > 0 ? "+" : "")\(rounded)"
    }

    /// A range that hugs the readings, so small changes are visible.
    private func chartRange(_ heart: HeartRateHistory) -> ClosedRange<Double> {
        let low = (heart.minimum ?? 60) - 5
        let high = (heart.maximum ?? 100) + 5
        return low...max(high, low + 10)
    }
}

#Preview {
    HeartRateScreen()
        .padding()
        .environment(AppModel())
}
