//
//  WorkoutView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import SwiftUI
import HealthKit

struct WorkoutView: View {
    var workout: HKWorkout
    @State var segmentDates: [Date] = []
    @State var segment: Int? = nil
    @State var distance: Double? = nil

    var segmentStart: Date {
        guard let segment, segment > 0 else {
            return workout.startDate
        }
        return segmentDates[segment-1]
    }

    var segmentEnd: Date {
        guard let segment, segment < segmentDates.count else {
            return workout.endDate
        }
        return segmentDates[segment]
    }

    func getSegments() {
        guard let events = workout.workoutEvents else {
            return
        }

        let segments = events.filter {
            $0.type == .segment
        }

        guard !segments.isEmpty else {
            return
        }

        guard segments.first!.dateInterval.start == workout.startDate,
              segments.last!.dateInterval.end == workout.endDate else {
            print("malformed segments: \(segments.first!.dateInterval.start) != \(workout.startDate) or \(segments.last!.dateInterval.end) != \(workout.endDate)")
            return
        }

        segmentDates = segments.dropLast().map {
            $0.dateInterval.end
        }
    }

    func updateDistance() {
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        guard let statistics = workout.allStatistics[distanceType] else {
            return
        }
        distance = statistics.sumQuantity()?.doubleValue(for: .meter())
    }

    var body: some View {
        Form {
            if !segmentDates.isEmpty {
                Section {
                    Picker("Segment", selection: $segment) {
                        Text("Total").tag(nil as Int?)
                        ForEach(0...segmentDates.count, id: \.self) { index in
                            Text("Segment \(index+1)").tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Section {
                Label(Formatters.duration(workout.duration), systemImage: "stopwatch")

                Label(distance != nil ? Formatters.distance(distance!) + " km" : "...", systemImage: "ruler")
                    .onAppear(perform: updateDistance)
            }
        }
        .navigationTitle(workout.startDate.formatted(date: .numeric, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: getSegments)
    }
}

//#Preview {
//    WorkoutView(workout: _)
//}
