//
//  RingGauge.swift
//  Whatch
//

import SwiftUI

/// A circular progress ring with anything in the middle.
struct RingGauge<Label: View>: View {
    /// Fill fraction; values outside `0...1` are clamped.
    var value: Double
    var tint: Color
    var lineWidth: CGFloat = Layout.ringWidth
    @ViewBuilder var label: Label

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: value)
            label
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    RingGauge(value: 0.7, tint: .green) {
        Text("70%").font(.title2.bold())
    }
    .padding()
}
