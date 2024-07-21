//
//  WorkoutManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import HealthKit
import CoreLocation

class WorkoutManager: NSObject {
    override init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
        }
        super.init()
    }

    private let healthStore: HKHealthStore?

    private let locationManager = LocationManager()

    private var session: HKWorkoutSession? = nil
    private var builder: HKLiveWorkoutBuilder? = nil
    private var routeBuilder: HKWorkoutRouteBuilder? = nil

    public var delegate: WorkoutManagerDelegate? = nil

    func requestAuthorization() async throws {
        guard let healthStore else {
            throw WorkoutError.healthDataUnavailable
        }

        let types: Set = [
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.heartRate),
            HKQuantityType(.runningSpeed),
        ]

        try await healthStore.requestAuthorization(toShare: types, read: types)

        try await locationManager.requestAuthorization()
    }

    func startWorkout() async throws -> Date? {
        guard let healthStore else {
            throw WorkoutError.healthDataUnavailable
        }
        guard session == nil else {
            return nil
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        session!.delegate = self

        builder = session!.associatedWorkoutBuilder()
        builder!.delegate = self
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: configuration)

        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

        let startDate: Date = .now
        session!.startActivity(with: startDate)
        try await builder!.beginCollection(at: startDate)
        locationManager.startUpdating(receivedUpdatedLocation)

        return startDate
    }

    private func receivedUpdatedLocation(_ locations: [CLLocation]) {
        guard let routeBuilder else {
            return
        }

        Task {
            do {
                try await routeBuilder.insertRouteData(locations)
            } catch {
                print("failed to insert route", error)
            }
        }
    }

    /// - Parameter startDate: The date when the old segment, that is currently being ended, originally started.
    /// - Returns: The date when the old segment ended and the new one started.
    func addSegment(startDate: Date) async -> Date? {
        guard let builder else { return nil }

        let endDate: Date = .now
        let event = HKWorkoutEvent(type: .segment,
                                   dateInterval: DateInterval(start: startDate, end: endDate),
                                   metadata: nil)

        do {
            try await builder.addWorkoutEvents([event])
        } catch {
            print("segment adding failed", error)
            return nil
        }

        return endDate
    }

    func endWorkout() async -> Bool {
        session?.end()

        locationManager.stopUpdating()

        do {
            try await builder?.endCollection(at: .now)
            guard let workout = try await builder?.finishWorkout() else {
                throw WorkoutError.savingFailed
            }

            try await routeBuilder?.finishRoute(with: workout, metadata: nil)
        } catch {
            print(error)
            return false
        }

        return true
    }

    func loadParameter(_ parameter: LoadableParameter, startDate: Date, endDate: Date) async -> Double? {
        guard let healthStore else {
            return nil
        }

        let sampleType = HKQuantityType(parameter.quantityTypeIdentifier)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withUnsafeContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: parameter.queryOptions) { _, statistics, error in

                guard let statistics else {
                    print(error as Any)
                    continuation.resume(returning: nil)
                    return
                }

                let value = parameter.getDoubleValue(statistics: statistics)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    enum LoadableParameter {
        case distance, averageSpeed, averageHeartRate

        var quantityTypeIdentifier: HKQuantityTypeIdentifier {
            switch self {
            case .distance:
                HKQuantityTypeIdentifier.distanceWalkingRunning
            case .averageSpeed:
                HKQuantityTypeIdentifier.runningSpeed
            case .averageHeartRate:
                HKQuantityTypeIdentifier.heartRate
            }
        }

        var queryOptions: HKStatisticsOptions {
            switch self {
            case .distance:
                []
            case .averageSpeed:
                HKStatisticsOptions.discreteAverage
            case .averageHeartRate:
                HKStatisticsOptions.discreteAverage
            }
        }

        func getDoubleValue(statistics: HKStatistics) -> Double? {
            switch self {
            case .distance:
                statistics.sumQuantity()?.doubleValue(for: .meter())
            case .averageSpeed:
                statistics.averageQuantity()?.doubleValue(for: .kilometerPerSecond()).inverse()
            case .averageHeartRate:
                statistics.averageQuantity()?.doubleValue(for: .countPerMinute())
            }
        }
    }

    enum WorkoutState {
        case started, ended
    }

    enum WorkoutError: Error {
        case healthDataUnavailable, savingFailed
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {

        if toState == .ended {
            delegate?.workoutManagerUpdated(workoutState: .ended)
        } else if toState == .running, fromState == .notStarted {
            delegate?.workoutManagerUpdated(workoutState: .started)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("session failed", error)
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else {
                return
            }

            let handlers: [HKQuantityType : (HKStatistics)->()] = [
                HKQuantityType(.distanceWalkingRunning): handleDistanceStatistics(_:),
                HKQuantityType(.runningSpeed): handleSpeedStatistics(_:),
                HKQuantityType(.heartRate): handleHeartRateStatistics(_:),
            ]

            if let handler = handlers[statistics.quantityType] {
                handler(statistics)
            }
        }
    }

    private func handleDistanceStatistics(_ statistics: HKStatistics) {
        guard let quantity = statistics.sumQuantity() else {
            return
        }

        let meters = quantity.doubleValue(for: .meter())

        delegate?.workoutManagerUpdated(distance: meters)
    }

    private func handleSpeedStatistics(_ statistics: HKStatistics) {
        guard let averageQuantity = statistics.averageQuantity(),
              let currentQuantity = statistics.mostRecentQuantity() else {
            return
        }

        let averageSecPerKm = averageQuantity.doubleValue(for: .kilometerPerSecond()).inverse()
        let currentSecPerKm = currentQuantity.doubleValue(for: .kilometerPerSecond()).inverse()

        delegate?.workoutManagerUpdated(averageSpeed: averageSecPerKm, currentSpeed: currentSecPerKm)
    }

    private func handleHeartRateStatistics(_ statistics: HKStatistics) {
        guard let averageQuantity = statistics.averageQuantity(),
              let currentQuantity = statistics.mostRecentQuantity() else {
            return
        }

        let averageBeatsPerMin = averageQuantity.doubleValue(for: .countPerMinute())
        let currentBeatsPerMin = currentQuantity.doubleValue(for: .countPerMinute())

        delegate?.workoutManagerUpdated(averageHeartRate: averageBeatsPerMin,
                                        currentHeartRate: currentBeatsPerMin)
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("event collected", workoutBuilder.workoutEvents.last as Any)
    }
}

extension WorkoutManager.WorkoutError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Your device does not support health data."
        case .savingFailed:
            "Failed to save the workout."
        }
    }
}

protocol WorkoutManagerDelegate {
    func workoutManagerUpdated(workoutState: WorkoutManager.WorkoutState)
    /// - Parameter distance: Total distance measured in meters.
    func workoutManagerUpdated(distance: Double)
    /// - Parameter averageSpeed: Average speed across the whole workout measured in seconds per kilometer.
    /// - Parameter currentSpeed: Latest available speed measured in seconds per kilometer.
    func workoutManagerUpdated(averageSpeed: Double, currentSpeed: Double)
    /// - Parameter averageHeartRate: Average heart rate across the whole workout measured in beats per minute.
    /// - Parameter currentHeartRate: Latest available heart rate measured in beats per minute.
    func workoutManagerUpdated(averageHeartRate: Double, currentHeartRate: Double)
}

extension Double {
    /// - Returns: One divided by the receiver, or zero if the receiver is zero.
    func inverse() -> Double {
        guard self != 0.0 else {
            return 0.0
        }
        return 1.0 / self
    }
}
