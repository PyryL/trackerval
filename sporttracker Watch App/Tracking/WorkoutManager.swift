//
//  WorkoutManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import HealthKit

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

    private var session: HKWorkoutSession? = nil
    private var builder: HKLiveWorkoutBuilder? = nil

    public var delegate: WorkoutManagerDelegate? = nil

    func requestAuthorization() async {
        guard let healthStore else { return }
        let types: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.heartRate),
            HKQuantityType(.runningSpeed),
        ]
        do {
            try await healthStore.requestAuthorization(toShare: types, read: types)
        } catch {
            // should never end up in here
            fatalError()
        }
    }

    func startWorkout() async -> Date? {
        guard let healthStore, session == nil else { return nil }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            print(error)
            return nil
        }

        session!.delegate = self

        builder = session!.associatedWorkoutBuilder()
        builder!.delegate = self
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        let startDate: Date = .now
        session!.startActivity(with: startDate)
        do {
            try await builder!.beginCollection(at: startDate)
        } catch {
            print("builder start failed", error)
            return nil
        }

        return startDate
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

    func loadParameter(_ parameter: LoadableParameter, startDate: Date, endDate: Date) async -> Double? {
        guard let healthStore else {
            return nil
        }

        let sampleType = HKQuantityType(parameter.quantityTypeIdentifier)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withUnsafeContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate) { _, statistics, error in

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
        case distance, averageHeartRate

        var quantityTypeIdentifier: HKQuantityTypeIdentifier {
            switch self {
            case .distance:
                HKQuantityTypeIdentifier.distanceWalkingRunning
            case .averageHeartRate:
                HKQuantityTypeIdentifier.heartRate
            }
        }

        func getDoubleValue(statistics: HKStatistics) -> Double? {
            switch self {
            case .distance:
                statistics.sumQuantity()?.doubleValue(for: .meter())
            case .averageHeartRate:
                statistics.averageQuantity()?.doubleValue(for: .countPerMinute())
            }
        }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("session state \(fromState.description) -> \(toState.description)")
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

        let averageKmPerSec = averageQuantity.doubleValue(for: .kilometerPerSecond())
        let currentKmPerSec = currentQuantity.doubleValue(for: .kilometerPerSecond())

        let averageSecPerKm = averageKmPerSec == 0 ? 0.0 : 1.0 / averageKmPerSec
        let currentSecPerKm = currentKmPerSec == 0 ? 0.0 : 1.0 / currentKmPerSec

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
