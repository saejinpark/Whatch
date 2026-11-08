//
//  Device.swift
//  Whatch
//

import Foundation
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

/// The few platform facts both apps need, behind one name.
enum Device {
    #if os(watchOS)
    static let name = "Apple Watch"
    static let shortName = "워치"
    static let symbol = "applewatch"
    static let counterpartName = "iPhone"
    static let counterpartShortName = "아이폰"
    static let counterpartSymbol = "iphone"
    #else
    static let name = "iPhone"
    static let shortName = "아이폰"
    static let symbol = "iphone"
    static let counterpartName = "Apple Watch"
    static let counterpartShortName = "워치"
    static let counterpartSymbol = "applewatch"
    #endif

    /// This device's battery right now.
    @MainActor
    static func batteryReading() -> BatteryReading {
        #if targetEnvironment(simulator)
        // Simulators report no battery; show something so the screens can be checked.
        return BatteryReading(level: 0.82, isCharging: false)
        #elseif os(watchOS)
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let state = device.batteryState
        return BatteryReading(level: level >= 0 ? Double(level) : nil,
                              isCharging: state == .charging || state == .full)
        #else
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let state = device.batteryState
        return BatteryReading(level: level >= 0 ? Double(level) : nil,
                              isCharging: state == .charging || state == .full)
        #endif
    }
}
