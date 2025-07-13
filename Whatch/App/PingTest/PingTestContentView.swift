//
//  PingTestContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/8/25.
//

import SwiftUI

struct PingTestContentView: View {
    @ObservedObject var pingManager = WatchPing.shared
    @State private var timer: Timer?

    var body: some View {
        
        VStack {
                // 연결 상태 카드
            VStack {
                GroupBox {
                    CenteredContainer {
                        LockUp(item: status)
                            .foregroundColor(status.color)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(status.color.opacity(0.2))
                    )
                } label: {
                    Label("연결 상태", systemImage: "antenna.radiowaves.left.and.right")
                }
                // Latency 강조
                Spacer()
                
                GroupBox {
                    Text(pingManager.latency.map { String(format: "%.3f 초", $0) } ?? "--")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundColor(.accentColor)
                } label: {
                    Label("지연시간", systemImage: "clock")
                }
                
                GroupBox {
                    LabeledContent {
                        Text("\(pingManager.lastPingSentAt.map(format) ?? "--")")
                    } label: {
                        Label("보낸 시각", systemImage: "arrow.up.circle")
                    }
                    LabeledContent {
                        Text("\(pingManager.lastPongReceivedAt.map(format) ?? "--")")
                    } label: {
                        Label("응답 시각", systemImage: "arrow.down.circle")
                    }
                } label: {
                    Label("상세 시간 정보", systemImage: "calendar")
                }
            }
        }
        .padding()
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                pingManager.ping()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    var status: PingStatus {
        switch pingManager.isReachable {
        case true: return .good
        case false: return .bad
        case nil: return .pending
        default: return .unknown
        }
    }

    func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

}

#Preview {
    PingTestContentView()
}
