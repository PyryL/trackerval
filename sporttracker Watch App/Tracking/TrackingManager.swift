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
        motionStartManager.motionStartCallback = motionStartTriggered
        AudioPlayer.setAudioSession()
    }

    private let endTracking: () -> ()

    @Published var status: TrackingStatus = .notStarted

    @Published var startDate: Date? = nil
    @Published var distance: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var currentHeartRate: Double = 0

    @Published var intervalStatus: IntervalStatus = .disabled
    @Published var segmentDates: [Date] = []
    @Published var isAddingSegment: Bool = false

    @Published var pacerInterval: Double? = nil
    private var pacerTimer: Timer? = nil

    @Published var motionStartEnabled: Bool = false
    let motionStartManager = MotionStartManager()


    let workoutManager = WorkoutManager()

    let newSegmentAudio = AudioPlayer(sound: .newSegment)
    let pacerAudio = AudioPlayer(sound: .pacer)

    func startWorkout() {
        guard case .notStarted = status, startDate == nil else {
            return
        }

        status = .starting

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
                self.status = .running
            }

            WKInterfaceDevice.current().play(.success)
        }
    }

    func addSegment() {
        guard case .running = status,
              !isAddingSegment,
              let segmentStart = segmentDates.last ?? startDate,
              -segmentStart.timeIntervalSinceNow >= 1.0 else {
            return
        }
        isAddingSegment = true

        Task {
            let segmentEnd: Date
            do {
                segmentEnd = try await self.workoutManager.addSegment(startDate: segmentStart)
            } catch {
                DispatchQueue.main.async {
                    self.isAddingSegment = false
                }
                print(error)
                return
            }

            DispatchQueue.main.async {
                self.segmentDates.append(segmentEnd)
                self.isAddingSegment = false

                var playAudio: Bool = true

                if self.intervalStatus == .preparedForInterval, self.motionStartEnabled {
                    self.intervalStatus = .waitingForMotion
                    self.motionStartManager.start()
                    playAudio = false
                } else if self.intervalStatus == .preparedForInterval || self.intervalStatus == .waitingForMotion {
                    self.intervalStatus = .ongoing
                    if let pacerInterval = self.pacerInterval {
                        self.pacerTimer?.invalidate()
                        self.pacerTimer = Timer.scheduledTimer(withTimeInterval: pacerInterval, repeats: true) { _ in
                            WKInterfaceDevice.current().play(.notification)
                            self.pacerAudio.play()
                        }
                    }
                } else if self.intervalStatus == .ongoing {
                    self.intervalStatus = .disabled
                    self.pacerTimer?.invalidate()
                    self.pacerTimer = nil
                }

                WKInterfaceDevice.current().play(.retry)
                if playAudio {
                    self.newSegmentAudio.play()
                }
            }
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

            AudioPlayer.unsetAudioSession()
            WKInterfaceDevice.current().play(.failure)
        }
    }

    func quitToMenu() {
        guard case .failed(_) = status else {
            return
        }
        endTracking()
    }

    private func motionStartTriggered() {
        motionStartManager.stop()

        guard case .running = status, intervalStatus == .waitingForMotion else {
            return
        }

        addSegment()
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
    case disabled, preparedForInterval, waitingForMotion, ongoing
}

enum TrackingStatus {
    case notStarted, starting, running, ending, failed(Error)
}
