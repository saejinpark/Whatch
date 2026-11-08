//
//  RotationScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// Which wrist rotation is being accumulated.
enum RotationAxis: String, CaseIterable {
    /// Turning left and right, like a steering wheel lying flat.
    case yaw
    /// Twisting the forearm, like turning a door knob.
    case roll

    var title: String {
        switch self {
        case .yaw: "가로"
        case .roll: "세로"
        }
    }

    var systemImage: String {
        switch self {
        case .yaw: "arrow.left.and.right"
        case .roll: "arrow.up.and.down"
        }
    }

    var next: RotationAxis {
        self == .yaw ? .roll : .yaw
    }
}

@MainActor
@Observable
final class RotationModel {
    private(set) var accumulator = RotationAccumulator()
    var axis: RotationAxis = .yaw {
        didSet { accumulator.reset() }
    }

    @ObservationIgnored private let feed = MotionFeed()

    var isPaused: Bool {
        accumulator.isPaused
    }

    func start() {
        feed.start { [weak self] sample in
            guard let self else { return }
            accumulator.add(angle: axis == .yaw ? sample.yaw : sample.roll)
        }
    }

    func stop() {
        feed.stop()
    }

    func togglePause() {
        accumulator.isPaused.toggle()
    }

    func reset() {
        accumulator.reset()
    }
}

struct RotationScreen: View {
    @State private var model = RotationModel()

    private let tint = Feature.rotation.tint

    var body: some View {
        let total = model.accumulator.totalDegrees

        ZStack {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.2), lineWidth: Layout.ringWidth)
                // A marker that travels round the ring with the wrist.
                Circle()
                    .trim(from: 0, to: 0.06)
                    .stroke(tint, style: StrokeStyle(lineWidth: Layout.ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90 - 10.8 + total))

                VStack(spacing: -2) {
                    Text("\(total >= 0 ? "+" : "")\(Int(total.rounded()))°")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("\(model.accumulator.turns.formatted(.number.precision(.fractionLength(1)))) 바퀴")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, Layout.ringWidth * 2)
            }
            .padding(Layout.ringWidth / 2)
            .aspectRatio(1, contentMode: .fit)
            .opacity(model.isPaused ? 0.5 : 1)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    model.togglePause()
                } label: {
                    Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                }
                .tint(tint)
                .accessibilityLabel(model.isPaused ? "재개" : "일시정지")

                Spacer()

                Button {
                    model.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("초기화")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(model.axis.title, systemImage: model.axis.systemImage) {
                    model.axis = model.axis.next
                }
                .accessibilityLabel("회전 축: \(model.axis.title)")
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

#Preview {
    NavigationStack {
        RotationScreen()
    }
}
