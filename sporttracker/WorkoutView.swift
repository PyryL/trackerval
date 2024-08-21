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
    @State var intervalSegments: [Int] = []
    @State var segment: Int? = nil
    @State var segmentCrop: (start: Double, end: Double) = (0.0, 1.0)
    @State var locations: [CLLocation] = []
    @State var distance: Double? = nil
    @State var inspectorDate: Date? = nil

    var startDate: Date {
        guard let segment, segment > 0 else {
            return workout.startDate
        }
        return segmentDates[segment-1]
    }

    var endDate: Date {
        guard let segment, segment < segmentDates.count else {
            return workout.endDate
        }
        return segmentDates[segment]
    }

    var segmentStart: Date {
        let duration = endDate.timeIntervalSince(startDate)
        return startDate.addingTimeInterval(segmentCrop.start * duration)
    }

    var segmentEnd: Date {
        let duration = endDate.timeIntervalSince(startDate)
        return startDate.addingTimeInterval(segmentCrop.end * duration)
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

        intervalSegments = []
        for (i, segment) in segments.enumerated() {
            if segment.metadata?["info.pyry.apps.trackerval.isInterval"] as? Bool == true {
                intervalSegments.append(i)
            }
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
                        if let intervalIndex = intervalSegments.firstIndex(of: index) {
                            Text("Segment \(index+1) (interval \(intervalIndex+1))").tag(index)
                        } else {
                            Text("Segment \(index+1)").tag(index)
                        }
                    }
                }
                .pickerStyle(.menu)
            }

            CropSlider(value: $segmentCrop)

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
                    .onChange(of: segmentStart) { updateDistance() }
                    .onChange(of: segmentEnd) { updateDistance() }
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

struct CropSlider: View {
    @Binding var value: (start: Double, end: Double)
    @State private var isDraggingStart: Bool? = nil

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: value.start * geo.size.width, height: 1)

                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 4)
                    .frame(width: (value.end - value.start) * geo.size.width, height: 30)

                Spacer()
                    .frame(width: (1.0 - value.end) * geo.size.width, height: 1)
            }
            .gesture(DragGesture(minimumDistance: 30.0)
                .onChanged { value in
                    let percentage = min(max(value.location.x / geo.size.width, 0.0), 1.0)

                    if isDraggingStart == nil {
                        let distanceStart = abs(percentage - self.value.start)
                        let distanceEnd = abs(percentage - self.value.end)
                        isDraggingStart = distanceStart < distanceEnd
                    }

                    if isDraggingStart!, percentage < self.value.end {
                        self.value.start = percentage
                    } else if !isDraggingStart!, percentage > self.value.start {
                        self.value.end = percentage
                    }
                }
                .onEnded { _ in
                    isDraggingStart = nil
                })
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

//#Preview {
//    WorkoutView(workout: _)
//}
