//
//  RotationTrackerContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct RotationTrackerContentView: View {
    @State private var tracker: RotationTracker

    init(axis: RotationAxis) {
        _tracker = State(initialValue: RotationTracker(axis: axis))
    }

    var body: some View {
        VStack {
            Spacer()

            LabeledContent {
                Text(tracker.totalDegrees.formatted(.number.precision(.fractionLength(1))) + "°")
            } label: {
                Label("누적 회전각", systemImage: "arrow.triangle.2.circlepath")
            }
            .labeledContentStyle(.prominent)

            Divider()

            HStack {
                Button {
                    tracker.togglePause()
                } label: {
                    Label(tracker.isPaused ? "재개" : "일시정지",
                          systemImage: tracker.isPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    tracker.reset()
                } label: {
                    Label("초기화", systemImage: "arrow.counterclockwise.circle")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .id(tracker.axis)
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
    }
}

#Preview {
    RotationTrackerContentView(axis: .yaw)
}
