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
                VStack {
                    Text("Tracking")
                    Text("\(trackingManager.distance) m")
                    Text("\(trackingManager.averageSpeed) min/km (average)")
                    Text("\(trackingManager.currentSpeed) min/km (current)")
                    Text("\(trackingManager.averageHeartRate) /min (average)")
                    Text("\(trackingManager.currentHeartRate) /min (current)")
                }
            } else {
                startingView
            }
        }
        .onAppear(perform: trackingManager.startWorkout)
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

#Preview {
    let trackingManager = TrackingManager()
    trackingManager.isStarted = true
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 5.911
    trackingManager.currentSpeed = 5.761
    trackingManager.averageHeartRate = 128
    trackingManager.currentHeartRate = 135
    return TrackingView(trackingManager: trackingManager)
}
