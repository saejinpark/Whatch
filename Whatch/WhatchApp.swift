//
//  WhatchApp.swift
//  Whatch
//
//  Created by 박세진 on 7/5/25.
//

import SwiftUI

@main
struct WhatchApp: App {
    let batteryStatusManager = BatteryStatusManager.shared
    let headingMonitorManager = HeadingMonitorManager.shared
    let sender = WatchSender.shared
    let receiver = WatchReceiver.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
