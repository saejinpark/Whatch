//
//  HeadingMonitorContentView.swift
//  Whatch
//

import SwiftUI

/// Shows which way the counterpart device is pointing, relative to this device.
struct HeadingMonitorContentView: View {
    let monitor: HeadingMonitor

    /// Rotation that lines the SF Symbol arrow up with the dial on each platform.
    #if os(watchOS)
    private let needleCorrection: Double = -12
    #else
    private let needleCorrection: Double = 12
    #endif

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)

            ZStack {
                ProtractorBackground()
                CenteredContainer {
                    if let heading = monitor.heading {
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: diameter / 2, weight: .thin))
                            .rotationEffect(.degrees(monitor.remoteHeading + needleCorrection))
                            .rotationEffect(.degrees(-heading))
                    }
                }
            }
        }
    }
}

#Preview {
    HeadingMonitorContentView(monitor: HeadingMonitor())
}
