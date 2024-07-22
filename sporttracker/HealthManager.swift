//
//  HealthManager.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 21.7.2024.
//

import HealthKit

class HealthManager {
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
        }
    }

    private var healthStore: HKHealthStore?

    func requestAuthorization() async throws {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
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

        try await healthStore.requestAuthorization(toShare: [], read: types)
    }

    func getWorkouts() async throws -> [HKWorkout] {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
        }

        let predicate = HKQuery.predicateForWorkouts(with: .running)

        let sortDescriptor = NSSortDescriptor(keyPath: \HKSample.startDate, ascending: false)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in

            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples else {
                    fatalError()
                }

                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }

        return samples.compactMap { result in
            guard let workout = result as? HKWorkout,
                  workout.sourceRevision.source.bundleIdentifier == "info.pyry.apps.sporttracker" else {

                return nil
            }

            return workout
        }
    }

    enum HealthError: Error {
        case healthNotAvailable
    }
}
