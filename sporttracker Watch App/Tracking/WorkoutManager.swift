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

    public var delegate: WorkoutManagerDelegate? = nil

    func requestAuthorization() async {
        guard let healthStore else { return }
        let types: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.heartRate),
            HKQuantityType(.runningGroundContactTime),
            HKQuantityType(.runningSpeed),
        ]
        do {
            try await healthStore.requestAuthorization(toShare: types, read: types)
        } catch {
            // should never here
            fatalError()
        }
    }

    func startWorkout() async -> Bool {
        guard let healthStore, session == nil else { return false }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            print(error)
            return false
        }

        session!.delegate = self

        let builder = session!.associatedWorkoutBuilder()
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        let startDate: Date = .now
        session!.startActivity(with: startDate)
        do {
            try await builder.beginCollection(at: startDate)
        } catch {
            print("builder start failed", error)
            return false
        }

        return true
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("session state \(fromState) -> \(toState)")
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

            if statistics.quantityType == HKQuantityType(.distanceWalkingRunning) {
                guard let quantity = statistics.sumQuantity() else {
                    return
                }
                let meters = quantity.doubleValue(for: .meter())
                delegate?.workoutManagerUpdated(distance: meters)
            }
            else if statistics.quantityType == HKQuantityType(.runningSpeed) {
                guard let averageQuantity = statistics.averageQuantity(),
                      let currentQuantity = statistics.mostRecentQuantity() else {
                    return
                }
                let averageMinPerKm = 1.0 / averageQuantity.doubleValue(for: .kilometerPerMinute())
                let currentMinPerKm = 1.0 / currentQuantity.doubleValue(for: .kilometerPerMinute())
                delegate?.workoutManagerUpdated(averageSpeed: averageMinPerKm,
                                                currentSpeed: currentMinPerKm)
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("event collected", workoutBuilder.workoutEvents.last as Any)
    }
}

extension HKUnit {
    static func kilometerPerMinute() -> HKUnit {
        let minuteUnit = HKUnit.minute()
        let kilometerUnit = HKUnit.meterUnit(with: .kilo)
        return kilometerUnit.unitDivided(by: minuteUnit)
    }
}

protocol WorkoutManagerDelegate {
    func workoutManagerUpdated(distance: Double)
    func workoutManagerUpdated(averageSpeed: Double, currentSpeed: Double)
}
