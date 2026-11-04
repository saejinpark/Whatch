//
//  AccelerometerContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct AccelerometerContentView: View {
    @State private var manager = AccelerometerManager()

    var body: some View {
        ScrollView {
            LabeledContent {
                Text(kilograms(manager.maxMass))
            } label: {
                Label("최고 기록", systemImage: "rosette")
            }
            .labeledContentStyle(.prominent)

            LabeledContent {
                Text(manager.acceleration.formatted(.number.precision(.fractionLength(2))) + "   G")
            } label: {
                Label("현재 가속도", systemImage: "speedometer")
            }
            Divider()

            LabeledContent {
                Text(kilograms(manager.equivalentMass))
            } label: {
                Label("팔에 실린 무게", systemImage: "scalemass")
            }
            Divider()

            LabeledContent {
                Text("\(manager.measurementCount)  회 ")
            } label: {
                Label("총 측정 횟수", systemImage: "number.circle")
            }
            Divider()

            Button {
                manager.reset()
            } label: {
                Label("초기화", systemImage: "arrow.counterclockwise.circle")
            }
        }
        .padding()
        .onAppear { manager.start() }
        .onDisappear { manager.stop() }
    }

    private func kilograms(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " kg"
    }
}

#Preview {
    NavigationStack {
        AccelerometerContentView()
    }
}
