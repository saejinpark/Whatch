//
//  ProminentLabeledContentStyle.swift
//  Whatch
//

import SwiftUI

/// Small caption over a large rounded number. Used for the headline value of a feature.
struct ProminentLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 4) {
            configuration.label
                .font(.caption)
                .foregroundStyle(.secondary)

            configuration.content
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension LabeledContentStyle where Self == ProminentLabeledContentStyle {
    static var prominent: ProminentLabeledContentStyle { .init() }
}
