//
//  ActivationModePicker.swift
//  Whatch
//

import SwiftUI

/// Segmented switch between "while held" and "toggle" behaviour.
struct ActivationModePicker: View {
    @Binding var selection: ActivationMode

    var body: some View {
        Picker("모드", selection: $selection) {
            ForEach(ActivationMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ActivationModePicker(selection: .constant(.hold))
}
