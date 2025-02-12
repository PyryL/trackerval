//
//  HealthManager.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 21.7.2024.
//

import HealthKit
import CoreLocation

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

    func getData(_ sampleType: HKQuantityType, workout: HKWorkout) async throws -> [HKQuantitySample] {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
        }

        let workoutPredicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in

            let query = HKSampleQuery(sampleType: sampleType, predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }
    }

    func getStatistics(_ sampleType: HKQuantityType, startDate: Date, endDate: Date, workout: HKWorkout) async throws -> HKStatistics {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
        }

        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, datePredicate])

        let options: HKStatisticsOptions

        switch sampleType.aggregationStyle {
        case .cumulative:
            options = .cumulativeSum
        case .discreteArithmetic, .discrete, .discreteTemporallyWeighted:
            options = [.discreteAverage, .discreteMin, .discreteMax]
        default:
            print("Unexpected sample type in HealthManager.getStatistics", sampleType, sampleType.aggregationStyle.rawValue)
            options = []
        }

        return try await withCheckedThrowingContinuation { continuation in

            let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: options) { _, statistics, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let statistics else {
                    fatalError()
                }

                continuation.resume(returning: statistics)
            }

            healthStore.execute(query)
        }
    }

    func getRoute(workout: HKWorkout) async throws -> [CLLocation] {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
        }

        let workoutRouteType = HKSeriesType.workoutRoute()
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in

            let query = HKSampleQuery(sampleType: workoutRouteType, predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let routes = samples as? [HKWorkoutRoute], let firstRoute = routes.first else {
                    continuation.resume(returning: [])
                    return
                }

                Task {
                    do {
                        let locations = try await self.getRouteLocations(route: firstRoute)
                        continuation.resume(returning: locations)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            healthStore.execute(query)
        }
    }

    private func getRouteLocations(route: HKWorkoutRoute) async throws -> [CLLocation] {
        guard let healthStore else {
            throw HealthError.healthNotAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in

            var completeRouteLocations = [CLLocation]()

            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let locations else {
                    fatalError()
                }

                completeRouteLocations.append(contentsOf: locations)

                if done {
                    continuation.resume(returning: completeRouteLocations)
                }
            }

            healthStore.execute(query)
        }
    }

    enum HealthError: Error {
        case healthNotAvailable
    }
}
