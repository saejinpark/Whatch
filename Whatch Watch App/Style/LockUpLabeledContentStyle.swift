//
//  LockUpLabeledContentStyle.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct LockUpLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
            configuration.content
        }
    }
}
