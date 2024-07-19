//
//  TrackingView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct TrackingView: View {
    @StateObject var trackingManager = TrackingManager()
    
    var body: some View {
        Group {
            if trackingManager.isStarted {
                activeTrackingView
            } else {
                startingView
            }
        }
        .onAppear(perform: trackingManager.startWorkout)
    }

    private var activeTrackingView: some View {
        NavigationStack {
            Form {
                TrackingNumericInfoLabel(
                    value: Formatters.distance(trackingManager.distance),
                    unit: "km",
                    systemImage: "ruler")
                TrackingNumericInfoLabel(
                    value: Formatters.duration(trackingManager.averageSpeed),
                    unit: "/km",
                    systemImage: "speedometer")
                TrackingNumericInfoLabel(
                    value: Formatters.heartRate(trackingManager.averageHeartRate),
                    unit: "/min",
                    systemImage: "heart")
            }
        }
    }

    private var startingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(.circular)
                .fixedSize(horizontal: true, vertical: true)
            Text("Starting...")
        }
    }
}

fileprivate struct TrackingNumericInfoLabel: View {
    var value: String
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
    }
}

#Preview {
    let trackingManager = TrackingManager()
    trackingManager.isStarted = true
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 351 // 5:51
    trackingManager.currentSpeed = 344 // 5:44
    trackingManager.averageHeartRate = 128.419
    trackingManager.currentHeartRate = 135
    return TrackingView(trackingManager: trackingManager)
}
