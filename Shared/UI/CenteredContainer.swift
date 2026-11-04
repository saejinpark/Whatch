//
//  CenteredContainer.swift
//  Whatch
//

import SwiftUI

/// Centers its content in all the space it is offered.
struct CenteredContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
