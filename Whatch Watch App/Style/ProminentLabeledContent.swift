//
//  ProminentLabeledContent.swift
//  Whatch
//
//  Created by 박세진 on 7/7/25.
//

import SwiftUI

struct ProminentLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 4) {
            configuration.label
                .font(.caption)
                .foregroundColor(.secondary)

            configuration.content
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
