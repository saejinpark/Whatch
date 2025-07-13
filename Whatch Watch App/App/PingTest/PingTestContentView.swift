//
//  PingTestContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/8/25.
//
import SwiftUI

struct PingTestContentView: View {
    @ObservedObject var pingManager = PhonePing.shared
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            CenteredContainer {
                LockUp(item: status)
                    .foregroundColor(status.color)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(status.color.opacity(0.2))
            )
            VStack {
                LabeledContent {
                    if let latency = pingManager.latency {
                        Text(String(format: "%.3f 초", latency))
                    } else {
                        Text("-- 초")
                    }
                } label: {
                    Text("지연 시간:")
                }
                LabeledContent {
                    if let sent = pingManager.lastPingSentAt {
                        Text(format(sent))
                    } else {
                        Text("--")
                    }
                } label: {
                    Text("보낸 시각:")
                }
                LabeledContent {
                    if let received = pingManager.lastPongReceivedAt {
                        Text(format(received))
                    } else {
                        Text("--")
                    }
                } label: {
                    Text("응답 시각:")
                }
            }.padding()
        }
        .onAppear {
            // 2초마다 ping() 호출
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
