//
//  AppModel.swift
//  Whatch
//

import Foundation

/// Owns the long-lived services and keeps the two devices in sync.
///
/// Both apps use this type. Each broadcasts its own `DeviceState` whenever it changes and
/// mirrors the other's in `remote`. Anything sent often (compass, wrist motion, the board,
/// pressure) is a stream the other device has to ask for, so nothing floods the link while
/// nobody is looking.
@MainActor
@Observable
final class AppModel {
    let session = ConnectivitySession()
    let battery = BatteryMonitor()
    let heading = HeadingMonitor()
    let altimeter = AltimeterService()
    let ranging = RangingService()
    let duel = DuelController()
    let ping: PingMonitor
    #if os(iOS)
    let flashlight = FlashlightController()
    let haptic = HapticController()
    #else
    let heartBroadcaster = HeartRateBroadcaster()
    let buzzPlayer = BuzzPlayer()
    #endif

    /// Whether this app is on screen.
    private(set) var isForeground = false
    /// The counterpart's last known state.
    private(set) var remote: DeviceState?
    /// Whether `remote` was reported during this connection, as opposed to restored from storage.
    private(set) var isRemoteLive = false
    /// The counterpart's heading, while this device's heading screen is open.
    private(set) var remoteHeading: Double?
    /// A screen the counterpart asked this device to show. The home view shows it and clears this.
    var pendingOpen: Feature?
    /// The two barometers compared, while the height screen is open on either device.
    private(set) var height = HeightDifference()
    #if os(iOS)
    /// This iPhone's calibration for estimating height from arm span, shared with the Watch.
    private(set) var calibratedArmSpanOffset = UserDefaults.standard.object(forKey: AppModel.armSpanKey) as? Double
    #endif

    /// This device's heading screen is open.
    @ObservationIgnored private var isHeadingVisible = false
    /// The counterpart's heading screen is open and wants our heading.
    @ObservationIgnored private var isHeadingRequested = false
    /// This device's height screen is open.
    @ObservationIgnored private var isAltitudeVisible = false
    /// Streams this device's open screens need from the counterpart.
    @ObservationIgnored private var wanted: Set<LiveStream> = []
    /// Streams the counterpart asked this device for.
    @ObservationIgnored private var requested: Set<LiveStream> = []
    /// A screen an open screen here wants the counterpart to show.
    @ObservationIgnored private var openRequest: Feature?
    /// Whether the counterpart has confirmed hearing where this device stands.
    @ObservationIgnored private var sync = LinkSync()
    @ObservationIgnored private var linkKeeper: Task<Void, Never>?

    #if os(iOS)
    /// The Watch Board as last sent by the Watch.
    private(set) var mirroredBoard: Board?
    /// The latest reading from the Watch's controller, and when it arrived.
    private(set) var controllerSample: ControllerSample?
    private(set) var controllerSampleDate = Date.distantPast
    /// Heart rate readings sent by the Watch.
    private(set) var heart = HeartRateHistory()
    /// Whether the Watch is broadcasting heart rate right now.
    private(set) var isHeartLive = false
    #else
    /// Whether the button on the controller screen is held down.
    var isControllerPressed = false
    /// Whether the iPhone is using this Watch as a controller right now.
    private(set) var isControllerActive = false
    /// What is being sent to the iPhone, for the controller screen to show.
    private(set) var controllerSample = ControllerSample()
    /// A command went out and the iPhone has not answered within a few seconds.
    private(set) var replyTimedOut = false
    @ObservationIgnored private var replyTimeout: Task<Void, Never>?
    @ObservationIgnored private let motionFeed = MotionFeed()
    @ObservationIgnored private lazy var controllerSender = LatestSender(session: session, minimumInterval: 0.05)
    @ObservationIgnored private lazy var boardSender = LatestSender(session: session)
    @ObservationIgnored private lazy var brightnessSender = LatestSender(session: session, minimumInterval: 0.1)
    @ObservationIgnored private var simulatedTime = 0.0
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
        updateAltimeter()
        // The link is often not up yet at this instant; the keeper repeats this until it lands.
        session.refresh()
        requestSync()
        startLinkKeeper()
        #if os(watchOS)
        updateControllerStream()
        #endif
    }

    /// Call when the app leaves the screen.
    func deactivate() {
        isForeground = false
        linkKeeper?.cancel()
        linkKeeper = nil
        #if os(iOS)
        // iOS switches both off in the background anyway; keep our state, and the Watch, honest.
        flashlight.setOn(false)
        haptic.setPlaying(false)
        #else
        updateControllerStream()
        #endif
        battery.stop()
        updateHeadingMonitor()
        updateAltimeter()
        // Telling the counterpart we left the screen also ends every stream it sends us.
        broadcastState()
    }

    // MARK: Streams

    /// Asks the counterpart to start or stop a stream, for as long as a screen here needs it.
    func setWanted(_ stream: LiveStream, _ isOn: Bool) {
        if isOn {
            wanted.insert(stream)
        } else {
            wanted.remove(stream)
        }
        session.send(.subscribe(stream, isOn: isOn))
        #if os(iOS)
        if !isOn, stream == .motion {
            controllerSample = nil
        }
        #endif
    }

    /// Asks the counterpart to show a feature's screen, now or as soon as it can be reached.
    func requestOpen(_ feature: Feature) {
        openRequest = feature
        session.send(.open(feature))
    }

    /// The screen that asked for `feature` closed; stop asking.
    func cancelOpenRequest(_ feature: Feature) {
        if openRequest == feature {
            openRequest = nil
        }
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

    /// Call when the height screen opens and closes.
    func setAltitudeVisible(_ visible: Bool) {
        isAltitudeVisible = visible
        if !visible {
            height.clearRemote()
        }
        setWanted(.pressure, visible)
        updateAltimeter()
    }

    /// Declares the two devices level, to cancel out the difference between their barometers.
    func calibrateHeight() {
        height.calibrate()
    }

    // MARK: Arm span

    private static let armSpanKey = "armSpanOffset"

    /// What to add to a measured arm span to get a height. The iPhone keeps the calibration; the Watch follows it.
    var armSpanOffset: Double {
        #if os(iOS)
        calibratedArmSpanOffset ?? ArmSpan.defaultOffset
        #else
        remote?.armSpanOffset ?? ArmSpan.defaultOffset
        #endif
    }

    var isArmSpanCalibrated: Bool {
        #if os(iOS)
        calibratedArmSpanOffset != nil
        #else
        remote?.armSpanOffset != nil
        #endif
    }

    #if os(iOS)
    /// Calibrates with someone whose height is known and whose arm span was just measured as `distance`.
    /// Returns `false` when the two cannot belong to the same person.
    @discardableResult
    func calibrateArmSpan(height: Double, distance: Double) -> Bool {
        guard let offset = ArmSpan.offset(height: height, distance: distance) else { return false }
        calibratedArmSpanOffset = offset
        UserDefaults.standard.set(offset, forKey: Self.armSpanKey)
        broadcastState()
        return true
    }

    func resetArmSpan() {
        calibratedArmSpanOffset = nil
        UserDefaults.standard.removeObject(forKey: Self.armSpanKey)
        broadcastState()
    }
    #endif

    private func resubscribe() {
        if isHeadingVisible {
            session.send(.headingSubscription(isOn: true))
        }
        for stream in wanted {
            session.send(.subscribe(stream, isOn: true))
        }
        if let openRequest {
            session.send(.open(openRequest))
        }
        ranging.announce()
    }

    private func updateHeadingMonitor() {
        if isForeground && (isHeadingVisible || isHeadingRequested) {
            heading.start()
        } else {
            heading.stop()
        }
    }

    private func updateAltimeter() {
        if isForeground && (isAltitudeVisible || requested.contains(.pressure)) {
            altimeter.start()
        } else {
            altimeter.stop()
        }
    }

    /// The counterpart can no longer be reached or left the screen: it is neither watching nor sending.
    private func counterpartWentAway() {
        remoteHeading = nil
        isHeadingRequested = false
        requested.removeAll()
        height.clearRemote()
        updateHeadingMonitor()
        updateAltimeter()
        #if os(iOS)
        controllerSample = nil
        isHeartLive = false
        #else
        updateControllerStream()
        #endif
    }

    // MARK: Derived state

    var link: LinkStatus {
        guard session.isSupported else { return .unsupported }
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
        state.flashlightBrightness = flashlight.brightness
        state.armSpanOffset = calibratedArmSpanOffset
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

    // MARK: iPhone → Watch

    #if os(iOS)
    /// Whether a controller reading arrived recently enough to steer by.
    var isControllerFresh: Bool {
        Date().timeIntervalSince(controllerSampleDate) < 2
    }

    /// Plays a tap pattern on the Watch. Returns `false` when the Watch cannot be reached.
    @discardableResult
    func sendBuzz(_ pattern: String) -> Bool {
        let pattern = MorseCode.sanitized(pattern)
        guard !pattern.isEmpty else { return false }
        return session.send(.buzz(pattern))
    }

    func resetHeartHistory() {
        heart.reset()
    }
    #endif

    // MARK: Watch → iPhone

    #if os(watchOS)
    var isRemoteFlashlightOn: Bool {
        isRemoteLive && remote?.isFlashlightOn == true
    }

    var isRemoteHapticOn: Bool {
        isRemoteLive && remote?.isHapticOn == true
    }

    /// The iPhone's torch brightness as last reported, `0.1...1`.
    var remoteFlashlightBrightness: Double {
        remote?.flashlightBrightness ?? 1
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

    /// Sets the iPhone's torch brightness. Safe to call on every turn of the crown.
    func setRemoteFlashlightBrightness(_ brightness: Double) {
        brightnessSender.offer(.setFlashlightBrightness(min(max(brightness, TorchLevel.minimumBrightness), 1)))
    }

    /// The Watch Board changed; pass it on if the iPhone is mirroring it.
    func boardDidChange(_ data: Data) {
        guard requested.contains(.board) else { return }
        boardSender.offer(.board(data))
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

    /// Streams wrist motion while the iPhone asks for it and this app is on screen.
    private func updateControllerStream() {
        let shouldRun = isForeground && requested.contains(.motion)
        guard shouldRun != isControllerActive else { return }
        isControllerActive = shouldRun
        if shouldRun {
            motionFeed.start { [weak self] sample in
                self?.forward(sample)
            }
        } else {
            motionFeed.stop()
            controllerSender.cancel()
            isControllerPressed = false
        }
    }

    private func forward(_ motion: MotionSample) {
        var sample = ControllerSample(tiltX: motion.gravityX, tiltY: motion.gravityY,
                                      yaw: motion.yaw, roll: motion.roll, isPressed: isControllerPressed)
        #if targetEnvironment(simulator)
        // No sensors here: trace a slow figure of eight with the button held, so the phone screens can be checked.
        simulatedTime += 0.02
        sample.yaw = 22 * sin(simulatedTime * 1.3)
        sample.roll = 16 * sin(simulatedTime * 2.6)
        sample.isPressed = true
        #endif
        controllerSample = sample
        controllerSender.offer(.controller(sample))
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
        altimeter.onChange = { [weak self] kPa in
            guard let self else { return }
            height.updateLocal(kPa)
            if requested.contains(.pressure) {
                session.send(.pressure(kPa))
            }
        }
        ranging.sendToken = { [weak self] token, isAnswer in
            self?.session.send(isAnswer ? .rangingAnswer(token) : .rangingOffer(token))
        }
        duel.send = { [weak self] message in
            self?.session.send(message)
        }
        #if os(iOS)
        flashlight.onStateChange = { [weak self] in
            self?.broadcastState()
        }
        haptic.onStateChange = { [weak self] in
            self?.broadcastState()
        }
        #else
        heartBroadcaster.onSample = { [weak self] bpm in
            self?.session.send(.heartRate(bpm))
        }
        #endif
    }

    /// Tells the counterpart where this device stands and what it wants, and keeps trying until it hears.
    private func requestSync() {
        sync.request()
        battery.refresh()
        session.publish(localState)
        // Coming on screen and the link coming up often land together; after this hop they share one greeting.
        Task { [weak self] in
            self?.attemptSync()
        }
    }

    private func attemptSync() {
        // Nothing can be delivered yet; the keeper comes back here once the link is up.
        guard session.isReachable, let ticket = sync.begin(now: Date()) else { return }
        Log.connectivity.debug("Greeting sent")
        session.sendAcknowledged(.state(localState)) { [weak self] delivered in
            guard let self, sync.finish(ticket, delivered: delivered) else { return }
            // The link is proven to work right now, so ask for everything we want from the counterpart.
            resubscribe()
            session.sendAcknowledged(.stateRequest) { [weak self] delivered in
                if !delivered { self?.requestSync() }
            }
        }
    }

    /// While this app is on screen, notices a link that came back unannounced and finishes any greeting still owed.
    private func startLinkKeeper() {
        guard linkKeeper == nil else { return }
        linkKeeper = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                session.refresh()
                attemptSync()
            }
        }
    }

    private func reachabilityChanged(_ reachable: Bool) {
        Log.connectivity.debug("Reachable \(reachable, privacy: .public)")
        if reachable {
            requestSync()
        } else {
            // Keep the last battery reading, but nothing about the counterpart is current any more.
            isRemoteLive = false
            counterpartWentAway()
        }
    }

    private func handle(_ message: WatchMessage, isLive: Bool) {
        switch message {
        case .controller, .heading, .pressure, .board, .ping, .pong:
            break // Too frequent or too large to log.
        default:
            Log.connectivity.debug("Received \(String(describing: message), privacy: .public)")
        }
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
        case .ping:
            break // Answered by the session itself.

        case .subscribe(let stream, let isOn):
            if isOn {
                requested.insert(stream)
            } else {
                requested.remove(stream)
            }
            started(stream, isOn: isOn)
        case .open(let feature):
            #if os(watchOS)
            let platform = Feature.Platform.watch
            #else
            let platform = Feature.Platform.phone
            #endif
            if feature.isAvailable(on: platform) {
                pendingOpen = feature
            }
        case .pressure(let kPa):
            if isAltitudeVisible { height.updateRemote(kPa) }
        case .duelStart(let round, let delay):
            duel.receiveStart(round: round, delay: delay)
            pendingOpen = .duel
        case .duelResult(let round, let milliseconds):
            duel.receiveResult(round: round, milliseconds: milliseconds)
        case .rangingOffer(let token):
            // The other device opened its radar; open ours so the two can find each other.
            if !ranging.isStarted {
                pendingOpen = .radar
            }
            ranging.receive(token: token, isAnswer: false)
        case .rangingAnswer(let token):
            ranging.receive(token: token, isAnswer: true)

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
        case .setFlashlightBrightness(let brightness):
            #if os(iOS)
            flashlight.brightness = min(max(brightness, TorchLevel.minimumBrightness), 1)
            broadcastState()
            #endif
        case .board(let data):
            #if os(iOS)
            if let board = Board(data: data) { mirroredBoard = board }
            #endif
        case .controller(let sample):
            #if os(iOS)
            controllerSample = sample
            controllerSampleDate = Date()
            #endif
        case .heartRate(let bpm):
            #if os(iOS)
            if bpm > 0 {
                if !isHeartLive { heart.reset() }
                heart.add(bpm)
                isHeartLive = true
            } else {
                isHeartLive = false
            }
            #endif
        case .buzz(let pattern):
            #if os(watchOS)
            buzzPlayer.play(MorseCode.sanitized(pattern))
            #endif
        }
    }

    /// The counterpart started or stopped wanting a stream from this device.
    private func started(_ stream: LiveStream, isOn: Bool) {
        switch stream {
        case .pressure:
            updateAltimeter()
            if isOn, let kPa = altimeter.pressure {
                session.send(.pressure(kPa))
            }
        case .board:
            #if os(watchOS)
            // Send the drawing as it stands; changes follow from the board screen.
            if isOn {
                let stored = UserDefaults.standard.data(forKey: BoardStore.storageKey) ?? Board().data
                boardSender.offer(.board(stored))
            }
            #endif
        case .motion:
            #if os(watchOS)
            updateControllerStream()
            #endif
        }
    }

    private func receive(_ state: DeviceState, isLive: Bool) {
        if isLive {
            let wasPresent = isRemoteLive && remote?.isForeground == true
            remote = state
            isRemoteLive = true
            if !state.isForeground {
                counterpartWentAway()
            } else if !wasPresent {
                // It is back on screen and has forgotten what we asked of it.
                resubscribe()
            }
            #if os(watchOS)
            replyTimeout?.cancel()
            replyTimedOut = false
            #endif
        } else if !isRemoteLive {
            // Restored from storage: only what does not go stale can be trusted.
            remote = DeviceState(batteryLevel: state.batteryLevel, isCharging: state.isCharging,
                                 timestamp: state.timestamp, armSpanOffset: state.armSpanOffset)
        }
    }
}
