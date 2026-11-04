//
//  FeatureRow.swift
//  Whatch
//

import SwiftUI

/// One entry in the feature picker.
struct FeatureRow: View {
    let feature: Feature

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: feature.systemImage)
        }
    }
}

#Preview {
    List {
        FeatureRow(feature: .accelerometer)
        FeatureRow(feature: .pingTest)
    }
}
