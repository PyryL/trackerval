//
//  TrackingManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import Foundation

class TrackingManager: ObservableObject {
    @Published var isStarted: Bool = false

    @Published var distance: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var currentSpeed: Double = 0

    let workoutManager = WorkoutManager()

    func startWorkout() {
        Task {
            workoutManager.delegate = self
            await workoutManager.requestAuthorization()
            guard await workoutManager.startWorkout() else {
                return
            }
            DispatchQueue.main.async {
                self.isStarted = true
            }
        }
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
}
