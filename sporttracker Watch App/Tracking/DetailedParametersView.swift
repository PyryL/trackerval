//
//  DetailedParametersView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.7.2024.
//

import SwiftUI

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
            } else if segment == trackingManager.segmentDates.count {
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
                systemImage: "ruler")
            .onChange(of: segment) { updateDistance() }
            .onChange(of: trackingManager.distance) { _, newValue in
                if segment == nil {
                    distance = newValue
                } else if isCurrentSegment {
                    updateDistance()
                }
            }

            TrackingNumericInfoLabel(
                value: averageSpeed != nil ? Formatters.duration(averageSpeed!, withFraction: false) : "...",
                unit: "/ km",
                systemImage: "speedometer")
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
                    Text("Total").tag(nil as Int?)
                    ForEach(0..<trackingManager.segmentDates.count, id: \.self) { index in
                        Text("Segment \(index+1)").tag(index)
                    }
                    if !trackingManager.segmentDates.isEmpty {
                        Text("Current").tag(trackingManager.segmentDates.count)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.navigationLink)
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
    let trackingManager = TrackingManager()
    trackingManager.isStarted = true
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
