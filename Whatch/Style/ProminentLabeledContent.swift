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
            HStack {
                configuration.label
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            configuration.content
                .font(.largeTitle)
        }
    }
}
