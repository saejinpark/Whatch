//
//  DescriptiveIconRow.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct DescriptiveIconRow<T: DescriptiveItem>: View {
    let item: T
    
    var body: some View {
        LabeledContent {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.description)
                        .font(.headline)
                        .accessibilityHidden(true)
                }
                HStack {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        } label: {
            Label(item.description, systemImage: item.systemImage)
                .frame(width: 44, height: 44)
                .labelStyle(.iconOnly)
        }
    }
}

