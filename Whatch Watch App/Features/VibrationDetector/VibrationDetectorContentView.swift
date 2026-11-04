//
//  VibrationDetectorContentView.swift
//  Whatch Watch App
//

import Charts
import SwiftUI

struct VibrationDetectorContentView: View {
    @State private var detector = VibrationDetector()

    var body: some View {
        Chart {
            ForEach(Array(detector.samples.enumerated()), id: \.offset) { index, delta in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Delta", delta)
                )
            }
        }
        .chartYScale(domain: 0...1.5)
        .frame(height: 160)
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
    }
}

#Preview {
    VibrationDetectorContentView()
}
