//
//  HeadingScreen.swift
//  Whatch
//

import SwiftUI

/// Shows where the other device points, on a compass that turns with this one.
struct HeadingScreen: View {
    let model: AppModel

    var body: some View {
        let mine = model.heading.heading
        let theirs = model.remoteHeading

        VStack(spacing: Layout.spacing) {
            ZStack {
                CompassDial(heading: mine, target: theirs, tint: Feature.heading.tint)
                VStack(spacing: 0) {
                    Text(theirs.map { "\(Int($0.rounded()))°" } ?? "--°")
                        .font(.system(size: Layout.heroFont * 0.45, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Feature.heading.tint)
                    Text(theirs.map(HeadingMath.cardinal(for:)) ?? Device.counterpartName)
                        .font(Layout.footnoteFont)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(alignment: .top) {
                // Marks the direction this device points.
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                    .offset(y: -8)
            }
            .padding(.top, 8)

            Text(caption(mine: mine, theirs: theirs))
                .font(Layout.footnoteFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption(mine: mine, theirs: theirs))
        .onAppear { model.setHeadingVisible(true) }
        .onDisappear { model.setHeadingVisible(false) }
    }

    private func caption(mine: Double?, theirs: Double?) -> String {
        guard let mine else { return "나침반을 준비하는 중이에요" }
        let own = "내 방향 \(Int(mine.rounded()))°"
        guard let theirs else {
            return "\(own)\n\(model.link.advice ?? "\(Device.counterpartName) 방향을 기다리는 중")"
        }
        let difference = Int(HeadingMath.difference(from: mine, to: theirs).rounded())
        return "\(own) · 차이 \(difference > 0 ? "+" : "")\(difference)°"
    }
}

#Preview {
    HeadingScreen(model: AppModel())
        .padding()
}
