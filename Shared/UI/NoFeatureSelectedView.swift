//
//  NoFeatureSelectedView.swift
//  Whatch
//

import SwiftUI

struct NoFeatureSelectedView: View {
    var body: some View {
        ContentUnavailableView("선택되지 않음", systemImage: "questionmark")
    }
}

#Preview {
    NoFeatureSelectedView()
}
