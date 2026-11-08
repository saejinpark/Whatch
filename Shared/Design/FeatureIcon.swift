//
//  FeatureIcon.swift
//  Whatch
//

import SwiftUI

/// The feature's symbol on a rounded square in its tint, like an app icon.
struct FeatureIcon: View {
    let feature: Feature
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: feature.systemImage)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(feature.tint.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(Feature.allCases) { FeatureIcon(feature: $0) }
    }
}
