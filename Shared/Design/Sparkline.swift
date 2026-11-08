//
//  Sparkline.swift
//  Whatch
//

import Charts
import SwiftUI

/// A bare line chart of recent values, oldest on the left.
struct Sparkline: View {
    let values: [Double]
    let tint: Color
    /// Fixed vertical range, or `nil` to fit the data.
    var range: ClosedRange<Double>?

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { index, value in
            AreaMark(x: .value("Index", index), y: .value("Value", value))
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.45), tint.opacity(0.02)],
                                                startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Index", index), y: .value("Value", value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: domain)
        .chartLegend(.hidden)
        .accessibilityHidden(true)
    }

    private var domain: ClosedRange<Double> {
        if let range { return range }
        let top = max(values.max() ?? 1, 0.001)
        return 0...(top * 1.15)
    }
}

#Preview {
    Sparkline(values: [12, 18, 15, 40, 22, 19, 25], tint: .teal)
        .frame(height: 80)
        .padding()
}
