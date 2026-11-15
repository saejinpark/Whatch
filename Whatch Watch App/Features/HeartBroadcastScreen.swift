//
//  HeartBroadcastScreen.swift
//  Whatch Watch App
//

import SwiftUI

/// Starts and stops sending live heart rate to the iPhone.
struct HeartBroadcastScreen: View {
    @Environment(AppModel.self) private var model

    private let tint = Feature.heartRate.tint

    var body: some View {
        let broadcaster = model.heartBroadcaster

        VStack(spacing: Layout.spacing) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(tint)
                    .symbolEffect(.pulse, isActive: broadcaster.isRunning)
                Text(broadcaster.bpm.map { "\(Int($0.rounded()))" } ?? "--")
                    .font(.system(size: Layout.heroFont, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .animation(.default, value: broadcaster.bpm)

            if let problem = broadcaster.problem {
                LinkAdvice(text: problem)
            } else {
                Text(caption(broadcaster))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Button {
                if broadcaster.isRunning {
                    broadcaster.stop()
                } else {
                    Task { await broadcaster.start() }
                }
            } label: {
                Label(broadcaster.isRunning ? "중계 끝내기" : "중계 시작",
                      systemImage: broadcaster.isRunning ? "stop.fill" : "dot.radiowaves.left.and.right")
            }
            .tint(broadcaster.isRunning ? .gray : tint)
            .disabled(broadcaster.isStarting)
        }
    }

    private func caption(_ broadcaster: HeartRateBroadcaster) -> String {
        if broadcaster.isStarting { return "센서를 준비하는 중" }
        guard broadcaster.isRunning else { return "심박을 아이폰 큰 화면에 띄워요. 건강 앱에는 저장하지 않아요" }
        if !model.session.isReachable { return "아이폰과 연결되면 보내기 시작해요" }
        return broadcaster.bpm == nil ? "첫 측정을 기다리는 중" : "아이폰으로 보내는 중"
    }
}

#Preview {
    HeartBroadcastScreen()
        .environment(AppModel())
}
