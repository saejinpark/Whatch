//
//  PingTestContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct PingTestContentView: View {
    let monitor: PingMonitor

    var body: some View {
        VStack {
            CenteredContainer {
                LockUp(item: monitor.status)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(monitor.status.tint.opacity(0.2))
            )

            VStack {
                LabeledContent("지연 시간:") {
                    Text(monitor.latency.map { $0.formatted(.number.precision(.fractionLength(3))) + " 초" } ?? "-- 초")
                }
                LabeledContent("보낸 시각:") {
                    Text(monitor.lastPingSentAt?.preciseTimeString ?? "--")
                }
                LabeledContent("응답 시각:") {
                    Text(monitor.lastPongReceivedAt?.preciseTimeString ?? "--")
                }
            }
            .padding()
        }
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }
}

#Preview {
    PingTestContentView(monitor: PingMonitor(session: ConnectivitySession()))
}
