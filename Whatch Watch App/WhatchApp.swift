//
//  WhatchApp.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/5/25.
//

import SwiftUI
import SwiftData

@main
struct Whatch_Watch_AppApp: App {
    let batteryStatusManager = BatteryStatusManager.shared
    let headingMonitorManager = HeadingMonitorManager.shared
    let sender = PhoneSender.shared
    let receiver = PhoneReceiver.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Pixel.self])
                .onAppear {
                    batteryStatusManager.startMonitoring()
                    headingMonitorManager.startMonitoring()
                }
                .onDisappear {
                    batteryStatusManager.stopMonitoring()
                    headingMonitorManager.stopMonitoring()
                }
        }
    }
}
