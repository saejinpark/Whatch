//
//  ProtractorBackground.swift
//  Whatch
//

import SwiftUI

/// Compass-style dial drawn behind the heading needle.
struct ProtractorBackground: View {
    enum Style {
        /// Twelve spokes with a label between each pair. Fits a Watch face.
        case compact
        /// Rings, tick marks every degree and labels every 10°. Fits a phone screen.
        case detailed
    }

    #if os(watchOS)
    var style: Style = .compact
    #else
    var style: Style = .detailed
    #endif

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: diameter / 2, y: diameter / 2)

            ZStack {
                switch style {
                case .compact:
                    spokes(diameter: diameter)
                    labels(every: 30, offset: 15, radius: diameter / 2, center: center)
                case .detailed:
                    Circle().stroke(.gray, lineWidth: 2).frame(width: diameter)
                    Circle().stroke(.gray, lineWidth: 1).frame(width: diameter * 0.82)
                    labels(every: 10, offset: 0, radius: diameter / 10, center: center)
                    spokes(diameter: diameter)
                    Circle().frame(width: 30)
                    ticks(every: 1, size: CGSize(width: 1, height: 5), radius: diameter / 7, center: center)
                    ticks(every: 5, size: CGSize(width: 2, height: 10), radius: diameter / 7, center: center)
                }
            }
        }
    }

    private func spokes(diameter: CGFloat) -> some View {
        ForEach(0..<12, id: \.self) { index in
            Rectangle()
                .frame(width: 1, height: diameter * 0.82)
                .rotationEffect(.degrees(Double(30 * index)))
        }
    }

    /// Upright degree labels placed around the dial.
    private func labels(every step: Int, offset: Double, radius: CGFloat, center: CGPoint) -> some View {
        ForEach(0..<(360 / step), id: \.self) { index in
            let angle = Double(step * index)
            Text("\(Int(angle))°")
                .rotationEffect(.degrees(-angle - offset))
                .font(.caption2)
                .position(center)
                .offset(y: -radius)
                .rotationEffect(.degrees(angle + offset))
        }
    }

    private func ticks(every step: Int, size: CGSize, radius: CGFloat, center: CGPoint) -> some View {
        ForEach(0..<(360 / step), id: \.self) { index in
            Rectangle()
                .frame(width: size.width, height: size.height)
                .position(center)
                .offset(y: -radius)
                .rotationEffect(.degrees(Double(step * index)))
        }
    }
}

#Preview("Compact") {
    ProtractorBackground(style: .compact)
}

#Preview("Detailed") {
    ProtractorBackground(style: .detailed)
}
