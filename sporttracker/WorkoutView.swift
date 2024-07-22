//
//  WorkoutView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import SwiftUI
import HealthKit
import CoreLocation
import MapKit
import Charts

struct WorkoutView: View {
    var workout: HKWorkout
    var healthManager: HealthManager
    @State var segmentDates: [Date] = []
    @State var segment: Int? = nil
    @State var locations: [CLLocation] = []
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

    var segmentLocations: ArraySlice<CLLocation> {
        guard let startIndex = locations.firstIndex(where: { $0.timestamp >= segmentStart }),
              let endIndex = locations.lastIndex(where: { $0.timestamp <= segmentEnd }),
              startIndex < endIndex else {

            return []
        }

        return locations[startIndex ... endIndex]
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

    func getLocations() async {
        do {
            locations = try await healthManager.getRoute(workout: workout)
        } catch {
            print("failed to load locations", error)
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
                Picker("Segment", selection: $segment) {
                    Text("Total").tag(nil as Int?)
                    ForEach(0...segmentDates.count, id: \.self) { index in
                        Text("Segment \(index+1)").tag(index)
                    }
                }
                .pickerStyle(.menu)
            }

            if !locations.isEmpty {
                Map {
                    MapPolyline(coordinates: segmentLocations.map {
                        CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                    })
                    .stroke(Color.red, lineWidth: 4)
                }
                .frame(height: 200)
            }

            HStack {
                Image(systemName: "stopwatch")
                Text(Formatters.duration(segmentEnd.timeIntervalSince(segmentStart)))

                Spacer()

                Text(distance != nil ? Formatters.distance(distance!) + " km" : "...")
                    .onAppear(perform: updateDistance)
                Image(systemName: "ruler")
            }

            WorkoutPlotView(sampleType: HKQuantityType(.heartRate),
                            value: { $0.doubleValue(for: .countPerMinute()) },
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)

            WorkoutPlotView(sampleType: HKQuantityType(.runningSpeed),
                            value: { $0.doubleValue(for: .kilometerPerSecond()).inverse() },
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(Formatters.speed(value.as(Double.self)!))
                    }
                }
            }
        }
        .navigationTitle(workout.startDate.formatted(date: .numeric, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: getSegments)
        .task {
            await getLocations()
        }
    }
}

//#Preview {
//    WorkoutView(workout: _)
//}
