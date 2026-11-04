//
//  RemoteSwitch.swift
//  Whatch Watch App
//

import Foundation

/// A boolean that lives on the iPhone. The Watch only requests changes and mirrors
/// whatever state the phone reports back.
@MainActor
@Observable
final class RemoteSwitch {
    private(set) var isOn = false

    @ObservationIgnored private let session: ConnectivitySession
    @ObservationIgnored private let makeRequest: (Bool) -> WatchMessage

    init(session: ConnectivitySession, request: @escaping (Bool) -> WatchMessage) {
        self.session = session
        self.makeRequest = request
    }

    /// Asks the phone for the opposite state. `isOn` changes only once the phone confirms.
    func toggle() {
        session.send(makeRequest(!isOn))
    }

    func apply(isOn: Bool) {
        self.isOn = isOn
    }
}
