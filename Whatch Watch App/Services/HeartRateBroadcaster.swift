//
//  HeartRateBroadcaster.swift
//  Whatch Watch App
//

import Foundation
import HealthKit

/// Reads live heart rate on the Watch so it can be shown on the iPhone.
///
/// The sensor only reports every few seconds during a workout session, so one is run for
/// the duration of the broadcast and then discarded: nothing is saved to Health.
@MainActor
@Observable
final class HeartRateBroadcaster: NSObject {
    private(set) var isRunning = false
    private(set) var isStarting = false
    /// The latest reading in beats per minute.
    private(set) var bpm: Double?
    /// Why the broadcast could not start, in words for the user.
    private(set) var problem: String?

    /// Called with each reading, and with zero when the broadcast stops.
    @ObservationIgnored var onSample: ((Double) -> Void)?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?

    private nonisolated static let heartRate = HKQuantityType(.heartRate)

    func start() async {
        guard !isRunning, !isStarting else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            problem = "이 기기에서는 건강 데이터를 쓸 수 없어요"
            return
        }
        isStarting = true
        defer { isStarting = false }
        problem = nil
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [Self.heartRate])

            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .other
            configuration.locationType = .unknown
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            let now = Date()
            session.startActivity(with: now)
            try await builder.beginCollection(at: now)
            isRunning = true
        } catch {
            Log.sensors.error("Heart rate broadcast failed to start: \(error.localizedDescription)")
            problem = "심박을 읽을 수 없어요. 건강 앱에서 권한을 확인해 주세요"
            session?.end()
            session = nil
            builder = nil
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        bpm = nil
        onSample?(0)
        let session = session, builder = builder
        self.session = nil
        self.builder = nil
        session?.end()
        Task {
            // End the collection, then throw the workout away instead of saving it.
            try? await builder?.endCollection(at: Date())
            builder?.discardWorkout()
        }
    }

    private func record(_ value: Double) {
        guard isRunning else { return }
        bpm = value
        onSample?(value)
    }

    private func failed() {
        guard isRunning else { return }
        stop()
        problem = "심박 측정이 중단됐어요"
    }
}

extension HeartRateBroadcaster: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(Self.heartRate),
              let quantity = workoutBuilder.statistics(for: Self.heartRate)?.mostRecentQuantity() else { return }
        let value = quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        Task { @MainActor in
            self.record(value)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension HeartRateBroadcaster: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState, date: Date) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.failed()
        }
    }
}
