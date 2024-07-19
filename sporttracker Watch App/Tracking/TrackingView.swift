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
                }
            } else {
                startingView
            }
        }
        .onAppear(perform: trackingManager.prepareToStart)
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
    return TrackingView(trackingManager: trackingManager)
}
