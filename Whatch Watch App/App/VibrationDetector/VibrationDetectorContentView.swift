//
//  VibrationDetectorContentView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI
import Charts

struct VibrationDetectorContentView: View {
    @StateObject private var manager = VibrationDetectorManager()

    var body: some View {
        Chart {
            ForEach(Array(manager.vibrationDeltas.enumerated()), id: \.offset) { index, delta in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Delta", delta)
                )
            }
        }
        .chartYScale(domain: 0...1.5)
        .frame(height: 160)
        .onAppear { manager.start() }
        .onDisappear { manager.stop() }
    }
}

#Preview {
    VibrationDetectorContentView()
}
