//
//  ContentView.swift
//  Whatch
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
            .navigationTitle(selectedFeature?.title ?? "")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("앱 목록", systemImage: "list.bullet") {
                        isPickerPresented = true
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                FeaturePicker(selection: $selectedFeature)
                    .presentationDetents([.medium])
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
        case .accelerometer, .rollTrackerX, .rollTrackerY, .vibrationDetector, .watchBoard:
            // Watch-only features; a stale selection from an old install lands here.
            NoFeatureSelectedView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
