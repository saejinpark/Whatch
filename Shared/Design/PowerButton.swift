//
//  PowerButton.swift
//  Whatch
//

import SwiftUI

/// A large round on/off button that glows in its tint while on.
struct PowerButton: View {
    let isOn: Bool
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let diameter = min(proxy.size.width, proxy.size.height)
                ZStack {
                    Circle()
                        .fill(isOn ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.gray.opacity(0.22)))
                    Circle()
                        .strokeBorder(tint.opacity(isOn ? 0 : 0.7), lineWidth: max(diameter * 0.02, 1.5))
                    Image(systemName: systemImage)
                        .font(.system(size: diameter * 0.4, weight: .semibold))
                        .foregroundStyle(isOn ? Color.black.opacity(0.8) : tint)
                        .contentTransition(.symbolEffect(.replace))
                }
                .shadow(color: tint.opacity(isOn ? 0.75 : 0), radius: diameter * 0.16)
                .frame(width: diameter, height: diameter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(duration: 0.25), value: isOn)
        .sensoryFeedback(.impact, trigger: isOn)
    }
}

#Preview {
    HStack {
        PowerButton(isOn: true, systemImage: "flashlight.on.fill", tint: .yellow) {}
        PowerButton(isOn: false, systemImage: "flashlight.off.fill", tint: .yellow) {}
    }
    .padding()
}
