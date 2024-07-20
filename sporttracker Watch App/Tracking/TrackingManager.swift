//
//  TrackingManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import Foundation
import WatchKit

class TrackingManager: ObservableObject {
    init(endTracking: @escaping () -> ()) {
        self.endTracking = endTracking
    }

    private let endTracking: () -> ()

    @Published var isStarted: Bool = false

    @Published var startDate: Date? = nil
    @Published var distance: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var currentHeartRate: Double = 0

    @Published var intervalStatus: IntervalStatus = .disabled
    @Published var segmentDates: [Date] = []


    let workoutManager = WorkoutManager()

    func startWorkout() {
        Task {
            workoutManager.delegate = self
            await workoutManager.requestAuthorization()
            guard let startDate = await workoutManager.startWorkout() else {
                return
            }
            DispatchQueue.main.async {
                self.isStarted = true
                self.startDate = startDate
            }
            WKInterfaceDevice.current().play(.success)
        }
    }

    func addSegment() {
        guard let segmentStart = segmentDates.last ?? startDate,
              -segmentStart.timeIntervalSinceNow >= 1.0 else {
            return
        }
        Task {
            if let segmentEnd = await self.workoutManager.addSegment(startDate: segmentStart) {
                DispatchQueue.main.async {
                    self.segmentDates.append(segmentEnd)

                    if self.intervalStatus == .preparedForInterval {
                        self.intervalStatus = .ongoing
                    } else if self.intervalStatus == .ongoing {
                        self.intervalStatus = .disabled
                    }
                }
                WKInterfaceDevice.current().play(.retry) // or .notification
            }
        }
    }

    func endWorkout() async {
        guard await workoutManager.endWorkout() else {
            return
        }
        endTracking()
        WKInterfaceDevice.current().play(.failure)
    }
}

extension TrackingManager: WorkoutManagerDelegate {
    func workoutManagerUpdated(distance: Double) {
        DispatchQueue.main.async {
            self.distance = distance
        }
    }

    func workoutManagerUpdated(averageSpeed: Double, currentSpeed: Double) {
        DispatchQueue.main.async {
            self.averageSpeed = averageSpeed
            self.currentSpeed = currentSpeed
        }
    }

    func workoutManagerUpdated(averageHeartRate: Double, currentHeartRate: Double) {
        DispatchQueue.main.async {
            self.averageHeartRate = averageHeartRate
            self.currentHeartRate = currentHeartRate
        }
    }
}

enum IntervalStatus {
    case disabled, preparedForInterval, ongoing
}
