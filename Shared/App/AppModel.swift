//
//  AppModel.swift
//  Whatch
//

import Foundation

/// Owns the long-lived services and keeps the two devices in sync.
///
/// Both apps use this type. Each broadcasts its own `DeviceState` whenever it changes and
/// mirrors the other's in `remote`; the Watch additionally sends commands to the iPhone.
@MainActor
@Observable
final class AppModel {
    let session = ConnectivitySession()
    let battery = BatteryMonitor()
    let heading = HeadingMonitor()
    let ping: PingMonitor
    #if os(iOS)
    let flashlight = FlashlightController()
    let haptic = HapticController()
    #endif

    /// Whether this app is on screen.
    private(set) var isForeground = false
    /// The counterpart's last known state.
    private(set) var remote: DeviceState?
    /// Whether `remote` was reported during this connection, as opposed to restored from storage.
    private(set) var isRemoteLive = false
    /// The counterpart's heading, while this device's heading screen is open.
    private(set) var remoteHeading: Double?
    /// This device's heading screen is open.
    @ObservationIgnored private var isHeadingVisible = false
    /// The counterpart's heading screen is open and wants our heading.
    @ObservationIgnored private var isHeadingRequested = false

    #if os(watchOS)
    /// A command went out and the iPhone has not answered within a few seconds.
    private(set) var replyTimedOut = false
    @ObservationIgnored private var replyTimeout: Task<Void, Never>?
    #endif

    init() {
        ping = PingMonitor(session: session)
        wire()
    }

    // MARK: Lifecycle

    /// Call when the app comes on screen.
    func activate() {
        isForeground = true
        battery.start()
        updateHeadingMonitor()
        broadcastState()
        session.send(.stateRequest)
        if isHeadingVisible {
            session.send(.headingSubscription(isOn: true))
        }
    }

    /// Call when the app leaves the screen.
    func deactivate() {
        isForeground = false
        #if os(iOS)
        // iOS switches both off in the background anyway; keep our state, and the Watch, honest.
        flashlight.setOn(false)
        haptic.setPlaying(false)
        #endif
        battery.stop()
        updateHeadingMonitor()
        broadcastState()
    }

    /// Call when the heading screen opens and closes. Starts the compass here and asks the
    /// counterpart to stream its heading only for as long as someone is looking.
    func setHeadingVisible(_ visible: Bool) {
        isHeadingVisible = visible
        if !visible {
            remoteHeading = nil
        }
        session.send(.headingSubscription(isOn: visible))
        updateHeadingMonitor()
    }

    private func updateHeadingMonitor() {
        if isForeground && (isHeadingVisible || isHeadingRequested) {
            heading.start()
        } else {
            heading.stop()
        }
    }

    // MARK: Derived state

    var link: LinkStatus {
        guard session.isActivated else { return .connecting }
        guard session.isPaired else { return .notPaired }
        guard session.isCounterpartInstalled else { return .appMissing }
        guard session.isReachable else { return .unreachable }
        #if os(watchOS)
        // The Watch can reach an iPhone whose app is in the background; the reverse is not possible.
        if let remote, isRemoteLive, !remote.isForeground {
            return .needsForeground
        }
        #endif
        return .connected
    }

    var localState: DeviceState {
        var state = DeviceState(
            batteryLevel: battery.reading.level,
            isCharging: battery.reading.isCharging,
            isForeground: isForeground,
            timestamp: Date().timeIntervalSince1970
        )
        #if os(iOS)
        state.isFlashlightOn = flashlight.isOn
        state.isHapticOn = haptic.isPlaying
        #endif
        return state
    }

    var remoteBattery: BatteryReading {
        guard let remote else { return BatteryReading() }
        // A live connection keeps the reading current; otherwise show how old it is.
        let isCurrent = isRemoteLive && session.isReachable
        return BatteryReading(
            level: remote.batteryLevel,
            isCharging: remote.isCharging,
            updatedAt: isCurrent ? nil : Date(timeIntervalSince1970: remote.timestamp)
        )
    }

    // MARK: Commands (Watch → iPhone)

    #if os(watchOS)
    var isRemoteFlashlightOn: Bool {
        isRemoteLive && remote?.isFlashlightOn == true
    }

    var isRemoteHapticOn: Bool {
        isRemoteLive && remote?.isHapticOn == true
    }

    /// Why a remote control may not respond right now, or `nil` when everything is fine.
    var remoteControlHint: String? {
        if let advice = link.advice { return advice }
        return replyTimedOut ? "아이폰이 응답하지 않아요" : nil
    }

    func setRemoteFlashlight(_ isOn: Bool) {
        sendCommand(.setFlashlight(isOn: isOn))
    }

    func setRemoteHaptic(_ isOn: Bool) {
        sendCommand(.setHaptic(isOn: isOn))
    }

    private func sendCommand(_ command: WatchMessage) {
        replyTimedOut = false
        replyTimeout?.cancel()
        guard session.send(command) else { return }
        replyTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.replyTimedOut = true
        }
    }
    #endif

    // MARK: Sync

    /// Tells the counterpart where this device stands, now and for whenever it next runs.
    func broadcastState() {
        battery.refresh()
        let state = localState
        session.send(.state(state))
        session.publish(state)
    }

    private func wire() {
        session.onMessage = { [weak self] message, isLive in
            self?.handle(message, isLive: isLive)
        }
        session.onReachabilityChange = { [weak self] reachable in
            self?.reachabilityChanged(reachable)
        }
        battery.onChange = { [weak self] in
            self?.broadcastState()
        }
        heading.onChange = { [weak self] degrees in
            guard let self, isHeadingRequested else { return }
            session.send(.heading(degrees))
        }
        #if os(iOS)
        flashlight.onStateChange = { [weak self] in
            self?.broadcastState()
        }
        haptic.onStateChange = { [weak self] in
            self?.broadcastState()
        }
        #endif
    }

    private func reachabilityChanged(_ reachable: Bool) {
        if reachable {
            broadcastState()
            session.send(.stateRequest)
            if isHeadingVisible {
                session.send(.headingSubscription(isOn: true))
            }
        } else {
            // Keep the last battery reading, but nothing about the counterpart is current any more.
            isRemoteLive = false
            remoteHeading = nil
            isHeadingRequested = false
            updateHeadingMonitor()
        }
    }

    private func handle(_ message: WatchMessage, isLive: Bool) {
        switch message {
        case .state(let state):
            receive(state, isLive: isLive)
        case .stateRequest:
            broadcastState()
        case .headingSubscription(let isOn):
            isHeadingRequested = isOn
            updateHeadingMonitor()
            // Send the current value at once rather than waiting for the compass to move.
            if isOn, let degrees = heading.heading {
                session.send(.heading(degrees))
            }
        case .heading(let degrees):
            if isHeadingVisible { remoteHeading = degrees }
        case .pong(let sentAt):
            ping.handlePong(sentAt: sentAt)
        case .setFlashlight(let isOn):
            #if os(iOS)
            let before = flashlight.isOn
            if isForeground { flashlight.setOn(isOn) }
            // A change is broadcast by the controller; answer a no-op or a refusal ourselves.
            if flashlight.isOn == before { broadcastState() }
            #endif
        case .setHaptic(let isOn):
            #if os(iOS)
            let before = haptic.isPlaying
            if isForeground { haptic.setPlaying(isOn) }
            if haptic.isPlaying == before { broadcastState() }
            #endif
        case .ping:
            break // Answered by the session itself.
        }
    }

    private func receive(_ state: DeviceState, isLive: Bool) {
        if isLive {
            remote = state
            isRemoteLive = true
            if !state.isForeground {
                // The counterpart left the screen: it is neither streaming nor watching.
                remoteHeading = nil
                isHeadingRequested = false
                updateHeadingMonitor()
            }
            #if os(watchOS)
            replyTimeout?.cancel()
            replyTimedOut = false
            #endif
        } else if !isRemoteLive {
            // Restored from storage: only the battery reading can be trusted.
            remote = DeviceState(batteryLevel: state.batteryLevel, isCharging: state.isCharging,
                                 timestamp: state.timestamp)
        }
    }
}
