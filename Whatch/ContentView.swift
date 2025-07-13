//
//  ContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isPresented = false
    @AppStorage("selectedFeature") var selectedFeature: Feature?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let feature = selectedFeature {
                    switch feature {
                    case .pingTest:
                        PingTestContentView()
                    case .flashlight:
                        FlashLightContentView()
                    case .hapticController:
                        HapticControllerContentView()
                    case .headingMonitor:
                        HeadingMonitorContentView()
                    case .batteryStatus:
                        BatteryStatusContentView()
                    default:
                        ContentUnavailableView(label: {
                            Label("선택되지 않음", systemImage: "questionmark")
                        })
                    }
                } else {
                    ContentUnavailableView(label: {
                        Label("선택되지 않음", systemImage: "questionmark")
                    })
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = true
                    } label: {
                        Label("app", systemImage: "list.bullet")
                    }
                }
            }
            .navigationTitle(selectedFeature != nil ? selectedFeature!.description : "")
            .sheet(isPresented: $isPresented) {
                AppSelector(selectedFeature: $selectedFeature)
                    .presentationDetents([.medium])
            }
            .onAppear {
                if selectedFeature == nil {
                    isPresented = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
