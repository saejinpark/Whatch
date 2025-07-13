//
//  LockUpView.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct LockUp<T: LockUpItem>: View {
    
    let item: T
    
    var body: some View {
        LabeledContent {
            Text(item.description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        } label: {
            Image(systemName: item.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
        }
        .labeledContentStyle(LockUpLabeledContentStyle())
    }
}
