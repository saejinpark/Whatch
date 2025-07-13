//
//  CenteredContainer.swift
//  Whatch
//
//  Created by 박세진 on 7/11/25.
//

import SwiftUI

struct CenteredContainer<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                content()
                Spacer()
            }
            Spacer()
        }
    }
}

