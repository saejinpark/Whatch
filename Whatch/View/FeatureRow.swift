//
//  FeatureRow.swift
//  Whatch
//
//  Created by 박세진 on 7/8/25.
//

import SwiftUI

struct FeatureRow: View {
    let feature: Feature
    var body: some View {
        LabeledContent {
            VStack {
                HStack {
                    Text(feature.description)
                        .font(.headline)
                        .accessibilityHidden(true)
                    Spacer()
                }
                HStack {
                    Text(feature.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        } label: {
            Label(feature.description, systemImage: feature.systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    FeatureRow(feature: .pingTest)
}
