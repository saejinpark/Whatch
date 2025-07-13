//
//  AccelerometerSampleView.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI
import SwiftUI

struct AccelerometerContentView: View {
    @StateObject private var manager = AccelerometerManager()

    var body: some View {
        ScrollView {
            
            LabeledContent {
                Text(String(format: "%.2f kg", manager.maxMass))
            } label: {
                Label("최고 기록", systemImage: "rosette")
            }
            .labeledContentStyle(ProminentLabeledContentStyle())
            
            LabeledContent {
                Text(String(format: "%.2f   G", manager.acceleration))
            } label: {
                Label("현재 가속도", systemImage: "speedometer")
            }
            Divider()

            LabeledContent {
                Text(String(format: "%.2f kg", manager.equivalentMass))
            } label: {
                Label("팔에 실린 무게", systemImage: "scalemass")
            }
            Divider()
            
            LabeledContent {
                Text("\(manager.measurementCount)  회 ")
            } label: {
                Label("총 측정 횟수", systemImage: "number.circle")
            }
            Spacer()
            Divider()
            Button {
                manager.reset()
            } label: {
                Label("초기화", systemImage: "arrow.counterclockwise.circle")
            }
        }
        .padding()
        .onAppear {
            manager.start()
        }
        .onDisappear {
            manager.stop()
        }
    }
}



#Preview {
    NavigationStack {
        VStack {
            AccelerometerContentView()
        }
    }
}
