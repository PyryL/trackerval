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

    private var workoutStartCallback: Optional<() -> ()> = nil

    private var workoutEndLastSegmentDate: Date? = nil
    private var workoutEndCallback: Optional<(Error?) -> ()> = nil

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
            HKQuantityType(.runningGroundContactTime),
            HKQuantityType(.runningStrideLength),
            HKQuantityType(.runningVerticalOscillation),
            HKQuantityType(.vo2Max),
        ]

        try await healthStore.requestAuthorization(toShare: types, read: types)

        try await locationManager.requestAuthorization()
    }

    /// - Returns: The date when the workout started, or `nil` if the workout was already started.
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

        session!.startActivity(with: .now)

        return try await withUnsafeThrowingContinuation { continuation in
            workoutStartCallback = {
                self.workoutStartCallback = nil

                guard let startDate = self.session!.startDate else {
                    fatalError()
                }

                Task {
                    do {
                        try await self.builder!.beginCollection(at: startDate)
                    } catch {
                        continuation.resume(throwing: error)
                        return
                    }

                    self.locationManager.startUpdating(self.receivedUpdatedLocation)

                    continuation.resume(returning: startDate)
                }
            }
        }
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
    /// - Parameter endDate: The date when the old segment ends. Defaults to the current date.
    /// - Returns: The date when the old segment ended and the new one started.
    func addSegment(startDate: Date, endDate: Date? = nil) async throws -> Date {
        guard let builder else {
            throw WorkoutError.notRunning
        }

        let endDate: Date = endDate ?? .now
        let event = HKWorkoutEvent(type: .segment,
                                   dateInterval: DateInterval(start: startDate, end: endDate),
                                   metadata: nil)

        try await builder.addWorkoutEvents([event])

        return endDate
    }

    /// - Parameter lastSegmentDate: The date when the last segment (that is currently running) started, if any.
    func endWorkout(lastSegmentDate: Date?) async throws {
        guard let session, workoutEndCallback == nil else {
            return
        }
        workoutEndLastSegmentDate = lastSegmentDate

        session.end()

        let _: Bool = try await withUnsafeThrowingContinuation { continuation in
            workoutEndCallback = { error in
                self.workoutEndCallback = nil

                self.session = nil
                self.builder = nil
                self.routeBuilder = nil

                DispatchQueue.main.async {
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    private func finishWorkoutEnding() {
        guard let endDate = session?.endDate else {
            fatalError()
        }

        Task {
            do {
                if let lastSegmentDate = self.workoutEndLastSegmentDate {
                    let _ = try await addSegment(startDate: lastSegmentDate, endDate: endDate)
                }
                self.workoutEndLastSegmentDate = nil

                try await builder?.endCollection(at: endDate)
                guard let workout = try await builder?.finishWorkout() else {
                    throw WorkoutError.savingFailed
                }

                locationManager.stopUpdating()
                try await routeBuilder?.finishRoute(with: workout, metadata: nil)
            } catch {
                workoutEndCallback?(error)
                return
            }

            workoutEndCallback?(nil)
        }
    }

    func loadParameter(_ parameter: LoadableParameter, startDate: Date, endDate: Date) async -> Double? {
        guard let healthStore else {
            return nil
        }

        let sampleType = HKQuantityType(parameter.quantityTypeIdentifier)
        let predicateOptions: HKQueryOptions = [.strictStartDate, .strictEndDate]
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: predicateOptions)

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

    enum WorkoutError: Error {
        case healthDataUnavailable, notRunning, savingFailed
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {

        if toState == .ended {
            finishWorkoutEnding()
        } else if toState == .running, fromState == .notStarted {
            workoutStartCallback?()
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
        //
    }
}

extension WorkoutManager.WorkoutError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Your device does not support health data."
        case .savingFailed:
            "Failed to save the workout."
        case .notRunning:
            nil
        }
    }
}

protocol WorkoutManagerDelegate {
    /// - Parameter distance: Total distance measured in meters.
    func workoutManagerUpdated(distance: Double)
    /// - Parameter averageSpeed: Average speed across the whole workout measured in seconds per kilometer.
    /// - Parameter currentSpeed: Latest available speed measured in seconds per kilometer.
    func workoutManagerUpdated(averageSpeed: Double, currentSpeed: Double)
    /// - Parameter averageHeartRate: Average heart rate across the whole workout measured in beats per minute.
    /// - Parameter currentHeartRate: Latest available heart rate measured in beats per minute.
    func workoutManagerUpdated(averageHeartRate: Double, currentHeartRate: Double)
}
