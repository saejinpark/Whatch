//
//  ContentView.swift
//  Whatch Watch App
//

import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("selectedFeature") private var selectedFeature: Feature?
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if let selectedFeature {
                    featureView(for: selectedFeature)
                } else {
                    NoFeatureSelectedView()
                }
            }
            .navigationTitle(selectedFeature?.title ?? "기능을 선택해주세요")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("앱 목록", systemImage: "list.bullet") {
                        isPickerPresented = true
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                FeaturePicker(selection: $selectedFeature)
            }
            .onAppear {
                if selectedFeature == nil {
                    isPickerPresented = true
                }
            }
        }
    }

    @ViewBuilder
    private func featureView(for feature: Feature) -> some View {
        switch feature {
        case .accelerometer:
            AccelerometerContentView()
        case .rollTrackerX:
            RotationTrackerContentView(axis: .yaw)
        case .rollTrackerY:
            RotationTrackerContentView(axis: .roll)
        case .vibrationDetector:
            VibrationDetectorContentView()
        case .watchBoard:
            WatchBoardContentView()
        case .pingTest:
            PingTestContentView(monitor: model.ping)
        case .flashlight:
            FlashlightContentView()
        case .hapticController:
            HapticControllerContentView()
        case .headingMonitor:
            HeadingMonitorContentView(monitor: model.heading)
        case .batteryStatus:
            BatteryStatusContentView(monitor: model.battery)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .modelContainer(for: Pixel.self, inMemory: true)
}
