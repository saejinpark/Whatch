//
//  WhatchWatchApp.swift
//  Whatch Watch App
//

import SwiftUI

@main
struct WhatchWatchApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    switch phase {
                    case .active: model.activate()
                    case .background: model.deactivate()
                    default: break
                    }
                }
                .task {
                    if SelfTest.isRequested {
                        await SelfTest.run(model: model)
                    }
                }
        }
    }
}
