//
//  DetailedParametersView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.7.2024.
//

import SwiftUI

struct DetailedParametersView: View {
    @ObservedObject var trackingManager: TrackingManager
    
    var body: some View {
        Form {
            TrackingNumericInfoLabel(
                date: trackingManager.startDate ?? .distantPast,
                systemImage: "stopwatch")
            TrackingNumericInfoLabel(
                value: Formatters.distance(trackingManager.distance),
                unit: "km",
                systemImage: "ruler")
            TrackingNumericInfoLabel(
                value: Formatters.duration(trackingManager.averageSpeed, withFraction: false),
                unit: "/km",
                systemImage: "speedometer")
            TrackingNumericInfoLabel(
                value: Formatters.heartRate(trackingManager.averageHeartRate),
                unit: "/min",
                systemImage: "heart")
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

    @State var value: String
    var date: Date?
    var unit: String
    var systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .padding(.trailing)
            Text(value)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .monospaced()
            Spacer(minLength: 0)
            Text(unit)
        }
        .updates(interval: 0.05, enabled: date != nil) {
            guard let date else { return }
            value = Formatters.duration(-date.timeIntervalSinceNow)
        }
    }
}

#Preview {
    let trackingManager = TrackingManager()
    trackingManager.isStarted = true
    trackingManager.startDate = Date(timeIntervalSinceNow: -758.1733) // 12:38
    trackingManager.segmentDates = [Date(timeIntervalSinceNow: -99.315)] // 1:39
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 351 // 5:51
    trackingManager.currentSpeed = 344 // 5:44
    trackingManager.averageHeartRate = 128.419
    trackingManager.currentHeartRate = 135
    return DetailedParametersView(trackingManager: trackingManager)
}
