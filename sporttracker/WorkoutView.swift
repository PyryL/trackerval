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
    @State var inspectorDate: Date? = nil

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
        distance = nil

        Task {
            do {
                let statistics = try await healthManager.getStatistics(HKQuantityType(.distanceWalkingRunning),
                                                                       startDate: segmentStart,
                                                                       endDate: inspectorDate ?? segmentEnd,
                                                                       workout: workout)
                let distance = statistics.sumQuantity()!.doubleValue(for: .meter())
                DispatchQueue.main.async {
                    self.distance = distance
                }
            } catch {
                print("failed to load distance", error)
            }
        }
    }

    var durationLabel: String {
        let durationEndDate = inspectorDate ?? segmentEnd
        let duration = durationEndDate.timeIntervalSince(segmentStart)
        return Formatters.duration(duration)
    }

    var lengthFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }

    var groundContactTimeFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
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
                    MapPolyline(coordinates: segmentLocations.map { $0.coordinate })
                        .stroke(Color.red, lineWidth: 4)

                    if let inspectorDate, let location = segmentLocations.last(where: { $0.timestamp <= inspectorDate }) {
                        Annotation("Inspection", coordinate: location.coordinate) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(.red)
                                .overlay(Circle().stroke(Color.white))
                        }
                        .annotationTitles(.hidden)
                    }
                }
                .frame(height: 200)
            }

            HStack {
                Image(systemName: "stopwatch")
                Text(durationLabel)

                Spacer()

                Text(distance != nil ? Formatters.distance(distance!) + " km" : "...")
                    .onAppear(perform: updateDistance)
                    .onChange(of: segment) { updateDistance() }
                    .onChange(of: inspectorDate) { updateDistance() }
                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
            }

            WorkoutPlotView(sampleType: HKQuantityType(.heartRate),
                            valueGetter: { $0.doubleValue(for: .countPerMinute()) },
                            formatter: { Formatters.heartRate($0) },
                            systemImage: "heart",
                            inspectorDate: $inspectorDate,
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)

            WorkoutPlotView(sampleType: HKQuantityType(.runningSpeed),
                            valueGetter: { $0.doubleValue(for: .kilometerPerSecond()).inverse() },
                            formatter: { Formatters.speed($0) },
                            systemImage: "speedometer",
                            inspectorDate: $inspectorDate,
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)

            WorkoutPlotView(sampleType: HKQuantityType(.runningStrideLength),
                            valueGetter: { $0.doubleValue(for: .meterUnit(with: .centi)) },
                            formatter: { lengthFormatter.string(from: Measurement(value: $0, unit: UnitLength.centimeters)) },
                            systemImage: "ruler",
                            inspectorDate: $inspectorDate,
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)

            WorkoutPlotView(sampleType: HKQuantityType(.runningGroundContactTime),
                            valueGetter: { $0.doubleValue(for: .secondUnit(with: .milli)) },
                            formatter: { groundContactTimeFormatter.string(from: Measurement(value: $0, unit: UnitDuration.milliseconds)) },
                            systemImage: "hourglass",
                            inspectorDate: $inspectorDate,
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)

            WorkoutPlotView(sampleType: HKQuantityType(.runningVerticalOscillation),
                            valueGetter: { $0.doubleValue(for: .meterUnit(with: .centi)) },
                            formatter: { lengthFormatter.string(from: Measurement(value: $0, unit: UnitLength.centimeters)) },
                            systemImage: "arrow.up.arrow.down",
                            inspectorDate: $inspectorDate,
                            segmentStart: segmentStart,
                            segmentEnd: segmentEnd,
                            workout: workout,
                            healthManager: healthManager)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text(Formatters.duration(value.as(Date.self)!.timeIntervalSince(segmentStart)))
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
