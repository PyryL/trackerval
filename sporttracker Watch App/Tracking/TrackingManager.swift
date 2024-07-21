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
        workoutManager.delegate = self
    }

    private let endTracking: () -> ()

    @Published var status: TrackingStatus = .starting

    @Published var startDate: Date? = nil
    @Published var distance: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var currentHeartRate: Double = 0

    @Published var intervalStatus: IntervalStatus = .disabled
    @Published var segmentDates: [Date] = []

    @Published var pacerInterval: Double? = nil
    private var pacerTimer: Timer? = nil


    let workoutManager = WorkoutManager()

    func startWorkout() {
        guard case .starting = status, startDate == nil else {
            return
        }

        Task {
            let startDate: Date?

            do {
                try await workoutManager.requestAuthorization()
                startDate = try await workoutManager.startWorkout()
            } catch {
                DispatchQueue.main.async {
                    self.status = .failed(error)
                }
                print(error)
                return
            }

            guard let startDate else {
                return
            }

            DispatchQueue.main.async {
                self.startDate = startDate
            }
        }
    }

    func addSegment() {
        guard case .running = status,
              let segmentStart = segmentDates.last ?? startDate,
              -segmentStart.timeIntervalSinceNow >= 1.0 else {
            return
        }

        Task {
            let segmentEnd: Date
            do {
                segmentEnd = try await self.workoutManager.addSegment(startDate: segmentStart)
            } catch {
                print(error)
                return
            }

            DispatchQueue.main.async {
                self.segmentDates.append(segmentEnd)

                if self.intervalStatus == .preparedForInterval {
                    self.intervalStatus = .ongoing
                    if let pacerInterval = self.pacerInterval {
                        self.pacerTimer?.invalidate()
                        self.pacerTimer = Timer.scheduledTimer(withTimeInterval: pacerInterval, repeats: true) { _ in
                            WKInterfaceDevice.current().play(.notification)
                        }
                    }
                } else if self.intervalStatus == .ongoing {
                    self.intervalStatus = .disabled
                    self.pacerTimer?.invalidate()
                    self.pacerTimer = nil
                }
            }

            WKInterfaceDevice.current().play(.retry) // or .notification
        }
    }

    func endWorkout() {
        pacerTimer?.invalidate()
        pacerTimer = nil

        status = .ending

        Task {
            do {
                try await workoutManager.endWorkout(lastSegmentDate: self.segmentDates.last)
            } catch {
                DispatchQueue.main.async {
                    self.status = .failed(error)
                }
                print(error)
                return
            }

            DispatchQueue.main.async {
                self.endTracking()
            }

            WKInterfaceDevice.current().play(.failure)
        }
    }

    func quitToMenu() {
        guard case .failed(_) = status else {
            return
        }
        endTracking()
    }
}

extension TrackingManager: WorkoutManagerDelegate {
    func workoutManagerUpdated(workoutState: WorkoutManager.WorkoutState) {
        if workoutState == .started {
            DispatchQueue.main.async {
                self.status = .running
            }
            WKInterfaceDevice.current().play(.success)
        }
    }

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

enum TrackingStatus {
    case starting, running, ending, failed(Error)
}
