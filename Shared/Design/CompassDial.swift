//
//  CompassDial.swift
//  Whatch
//

import SwiftUI

/// A compass rose that turns with the device, plus a needle for a second heading.
///
/// The top of the dial is where this device points. North on the rose therefore sits at
/// `-heading`, and the needle shows where the other device points on the same rose.
struct CompassDial: View {
    /// This device's heading in degrees, or `nil` when unknown (the rose then stays north-up).
    var heading: Double?
    /// The other device's heading in degrees, or `nil` to hide the needle.
    var target: Double?
    var tint: Color

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let rotation = -(heading ?? 0)
            context.translateBy(x: size.width / 2, y: size.height / 2)

            var rose = context
            rose.rotate(by: .degrees(rotation))

            for degree in stride(from: 0, to: 360, by: 10) {
                let isMajor = degree.isMultiple(of: 30)
                var tick = rose
                tick.rotate(by: .degrees(Double(degree)))
                let width: CGFloat = isMajor ? max(radius * 0.02, 1.5) : 1
                let length = radius * (isMajor ? 0.11 : 0.06)
                tick.fill(Path(CGRect(x: -width / 2, y: -radius, width: width, height: length)),
                          with: .color(isMajor ? Color.primary : Color.secondary))
            }

            for (index, letter) in ["N", "E", "S", "W"].enumerated() {
                let angle = Double(index) * 90
                var label = rose
                label.rotate(by: .degrees(angle))
                label.translateBy(x: 0, y: -radius * 0.6)
                label.rotate(by: .degrees(-angle - rotation)) // Keep the letter upright.
                label.draw(
                    Text(letter)
                        .font(.system(size: radius * 0.17, weight: .bold, design: .rounded))
                        .foregroundStyle(index == 0 ? Color.red : Color.primary),
                    at: .zero
                )
            }

            if let target {
                var needle = rose
                needle.rotate(by: .degrees(target))
                var arrow = Path()
                arrow.move(to: CGPoint(x: 0, y: -radius * 0.87))
                arrow.addLine(to: CGPoint(x: radius * 0.09, y: -radius * 0.72))
                arrow.addLine(to: CGPoint(x: -radius * 0.09, y: -radius * 0.72))
                arrow.closeSubpath()
                needle.fill(arrow, with: .color(tint))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.linear(duration: 0.1), value: heading)
        .accessibilityHidden(true)
    }
}

#Preview {
    CompassDial(heading: 30, target: 120, tint: .cyan)
        .padding()
}
