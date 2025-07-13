//
//  FeatureRow.swift
//  Whatch Watch App
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI

struct FeatureRow: View {
    let feature: Feature
    var body: some View {
        Group {
            Text(feature.description)
                .font(.headline)
            Text(feature.detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FeatureRow(feature: .accelerometer)
}
