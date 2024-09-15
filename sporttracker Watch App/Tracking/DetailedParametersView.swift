//
//  DetailedParametersView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.7.2024.
//

import SwiftUI
import HealthKit

struct DetailedParametersView: View {
    @ObservedObject var trackingManager: TrackingManager
    @State var segment: Int? = nil

    @State private var distance: Double? = 0
    @State private var averageSpeed: Double? = 0
    @State private var averageHeartRate: Double? = nil

    private var isCurrentSegment: Bool {
        segment == trackingManager.segmentDates.count
    }

    /// End date of the selected segment, if it's not total or current.
    private var segmentEndDate: Date? {
        guard let segment, !isCurrentSegment else {
            return nil
        }

        return trackingManager.segmentDates[segment]
    }

    /// Start date of the selected segment.
    private var segmentStartDate: Date {
        guard let segment, segment > 0 else {
            return trackingManager.startDate ?? .distantPast
        }

        return trackingManager.segmentDates[segment-1]
    }

    private var segmentDuration: Double {
        guard let segmentEndDate else {
            return 0
        }

        return segmentEndDate.timeIntervalSince(segmentStartDate)
    }

    var intervalSegments: [Int] {
        let segments: [HKWorkoutEvent]
        do {
            segments = try trackingManager.workoutManager.getSegments()
        } catch {
            print("could not load segments", error)
            return []
        }

        if trackingManager.segmentDates.count != segments.count {
            print("WARNING! count of segment dates does not match builder segments")
            return []
        }

        var result: [Int] = []

        for (i, segment) in segments.enumerated() {
            if segment.metadata?["info.pyry.apps.trackerval.isInterval"] as? Bool == true {
                result.append(i)
            }
        }

        return result
    }

    private func updateDistance() {
        guard segment != nil else {
            distance = trackingManager.distance
            return
        }

        distance = nil

        Task {
            guard let distance = await trackingManager.workoutManager.loadParameter(.distance, startDate: segmentStartDate, endDate: segmentEndDate ?? .now) else {
                return
            }

            DispatchQueue.main.async {
                self.distance = distance
            }
        }
    }

    private func updateSpeed() {
        guard segment != nil else {
            averageSpeed = trackingManager.averageSpeed
            return
        }

        averageSpeed = nil

        Task {
            let averageSpeed = await trackingManager.workoutManager.loadParameter(.averageSpeed, startDate: segmentStartDate, endDate: segmentEndDate ?? .now)

            DispatchQueue.main.async {
                self.averageSpeed = averageSpeed
            }
        }
    }

    private func updateHeartRate() {
        guard segment != nil else {
            averageHeartRate = trackingManager.averageHeartRate
            return
        }

        averageHeartRate = nil

        Task {
            let averageHeartRate = await trackingManager.workoutManager.loadParameter(.averageHeartRate, startDate: segmentStartDate, endDate: segmentEndDate ?? .now)

            DispatchQueue.main.async {
                self.averageHeartRate = averageHeartRate
            }
        }
    }

    var body: some View {
        Form {
            if segment == nil {
                TrackingNumericInfoLabel(
                    date: trackingManager.startDate ?? .distantPast,
                    systemImage: "stopwatch")
            } else if isCurrentSegment {
                TrackingNumericInfoLabel(
                    date: trackingManager.segmentDates.last ?? .distantPast,
                    systemImage: "stopwatch")
            } else {
                TrackingNumericInfoLabel(
                    value: Formatters.duration(segmentDuration),
                    unit: "",
                    systemImage: "stopwatch")
            }

            TrackingNumericInfoLabel(
                value: distance != nil ? Formatters.distance(distance!) : "...",
                unit: "km",
                systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
            .onAppear(perform: updateDistance)
            .onChange(of: segment) { updateDistance() }
            .onChange(of: trackingManager.distance) { _, newValue in
                if segment == nil {
                    distance = newValue
                } else if isCurrentSegment {
                    updateDistance()
                }
            }

            TrackingNumericInfoLabel(
                value: averageSpeed != nil ? Formatters.speed(averageSpeed!) : "...",
                unit: "/ km",
                systemImage: "speedometer")
            .onAppear(perform: updateSpeed)
            .onChange(of: segment) { updateSpeed() }
            .onChange(of: trackingManager.averageSpeed) { _, newValue in
                if segment == nil {
                    averageSpeed = newValue
                } else if isCurrentSegment {
                    updateSpeed()
                }
            }

            TrackingNumericInfoLabel(
                value: averageHeartRate != nil ? Formatters.heartRate(averageHeartRate!) : "...",
                unit: "",
                systemImage: "heart")
            .onAppear(perform: updateHeartRate)
            .onChange(of: segment) { updateHeartRate() }
            .onChange(of: trackingManager.averageHeartRate) { _, newValue in
                if segment == nil {
                    averageHeartRate = newValue
                } else if isCurrentSegment {
                    updateHeartRate()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Picker(selection: $segment) {
                    Label("Total", systemImage: "sum").tag(nil as Int?)
                    if !trackingManager.segmentDates.isEmpty {
                        Label("Current", systemImage: "play")
                            .tag(trackingManager.segmentDates.count)
                    }
                    ForEach((0..<trackingManager.segmentDates.count).reversed(), id: \.self) { index in
                        segmentLabel(index: index).tag(index)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    private func segmentLabel(index: Int) -> some View {
        Group {
            if let intervalIndex = intervalSegments.firstIndex(of: index) {
                Label("Interval \(intervalIndex+1)", systemImage: "\(index+1).circle")
            } else {
                Label("Segment", systemImage: "\(index+1).circle")
            }
        }
    }
}

fileprivate struct TrackingNumericInfoLabel: View {
    init(value: String, unit: String, systemImage: String) {
        self.value = value
        self.date = nil
        self.unit = unit
        self.systemImage = systemImage
    }

    init(date: Date, systemImage: String) {
        self.value = ""
        self.date = date
        self.unit = ""
        self.systemImage = systemImage
    }

    var value: String
    var date: Date?
    var unit: String
    var systemImage: String
    @State private var updatingValue: String? = nil

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .padding(.trailing)
            Text(updatingValue ?? value)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .monospaced()
            Spacer(minLength: 0)
            Text(unit)
        }
        .updates(interval: 0.05, enabled: date != nil) {
            guard let date else { return }
            updatingValue = Formatters.duration(-date.timeIntervalSinceNow)
        }
    }
}

#Preview {
    let trackingManager = TrackingManager(isIndoor: false, endTracking: { })
    trackingManager.status = .running
    trackingManager.startDate = Date(timeIntervalSinceNow: -758.1733)
    trackingManager.segmentDates = [
        Date(timeIntervalSinceNow: -445.8733),
        Date(timeIntervalSinceNow: -206.9561),
    ]
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 351 // 5:51
    trackingManager.currentSpeed = 344 // 5:44
    trackingManager.averageHeartRate = 128.419
    trackingManager.currentHeartRate = 135
    return NavigationStack {
        DetailedParametersView(trackingManager: trackingManager)
    }
}

/*
 .now   0
                        3:27.0 and increasing
 segDate[1] −206.9561
                        3:58.9
 segDate[0] -445.8733
                        5:12.3
 startDate  -758.1733    (12:38.2 ago)
 */
