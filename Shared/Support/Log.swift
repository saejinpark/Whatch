//
//  Log.swift
//  Whatch
//

import Foundation
import os

/// App-wide loggers. Use these instead of `print` so output is filterable in Console.app.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.pinocchio.Whatch"

    static let connectivity = Logger(subsystem: subsystem, category: "Connectivity")
    static let sensors = Logger(subsystem: subsystem, category: "Sensors")
    static let features = Logger(subsystem: subsystem, category: "Features")
}
