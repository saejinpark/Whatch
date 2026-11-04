//
//  PingTestContentView.swift
//  Whatch
//

import SwiftUI

struct PingTestContentView: View {
    let monitor: PingMonitor

    var body: some View {
        VStack {
            GroupBox {
                CenteredContainer {
                    LockUp(item: monitor.status)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(monitor.status.tint.opacity(0.2))
                )
            } label: {
                Label("연결 상태", systemImage: "antenna.radiowaves.left.and.right")
            }

            Spacer()

            GroupBox {
                Text(monitor.latency.map { $0.formatted(.number.precision(.fractionLength(3))) + " 초" } ?? "--")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            } label: {
                Label("지연시간", systemImage: "clock")
            }

            GroupBox {
                LabeledContent {
                    Text(monitor.lastPingSentAt?.preciseTimeString ?? "--")
                } label: {
                    Label("보낸 시각", systemImage: "arrow.up.circle")
                }
                LabeledContent {
                    Text(monitor.lastPongReceivedAt?.preciseTimeString ?? "--")
                } label: {
                    Label("응답 시각", systemImage: "arrow.down.circle")
                }
            } label: {
                Label("상세 시간 정보", systemImage: "calendar")
            }
        }
        .padding()
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }
}

#Preview {
    PingTestContentView(monitor: PingMonitor(session: ConnectivitySession()))
}
