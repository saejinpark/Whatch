//
//  RollTrackerYContentView.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI

struct RollTrackerYContentView: View {
    @StateObject private var manager = RollTrackerYManager()

    var body: some View {
        VStack {
            Spacer()

            // ✅ 누적 회전각 (강조 표시)
            LabeledContent {
                Text(String(format: "%.1f°", manager.totalRotationDegrees))
            } label: {
                Label("누적 회전각", systemImage: "arrow.triangle.2.circlepath")
            }
            .labeledContentStyle(ProminentLabeledContentStyle())

            Divider()

            // ✅ 수동 일시정지 및 초기화 버튼
            HStack {
                Button {
                    manager.togglePause()
                } label: {
                    Label(manager.isPaused ? "재개" : "일시정지", systemImage: manager.isPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    manager.reset()
                } label: {
                    Label("초기화", systemImage: "arrow.counterclockwise.circle")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            manager.startTracking()
        }
        .onDisappear {
            manager.stopTracking()
        }
    }
}

#Preview {
    RollTrackerYContentView()
}

