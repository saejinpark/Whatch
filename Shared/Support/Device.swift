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
    static let counterpartName = "아이폰"
    /// Counterpart name with the Korean subject particle attached ("아이폰이").
    static let counterpartSubject = "아이폰이"
    #else
    static let name = "iPhone"
    static let counterpartName = "워치"
    /// Counterpart name with the Korean subject particle attached ("워치가").
    static let counterpartSubject = "워치가"
    #endif

    @MainActor
    static func enableBatteryMonitoring() {
        #if os(watchOS)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        #else
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    /// Battery level in `0...1`, or a negative value when unknown.
    @MainActor
    static var batteryLevel: Float {
        #if os(watchOS)
        WKInterfaceDevice.current().batteryLevel
        #else
        UIDevice.current.batteryLevel
        #endif
    }
}
