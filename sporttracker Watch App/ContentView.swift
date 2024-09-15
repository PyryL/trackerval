//
//  ContentView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct ContentView: View {
    @State var isTracking: TrackingState = .disabled

    var body: some View {
        switch isTracking {
        case .disabled:
            MenuView(startTracking: { isIndoor in
                isTracking = .enabled(isIndoor: isIndoor)
            })
        case .enabled(let isIndoor):
            TrackingView(isIndoor: isIndoor, endTracking: { isTracking = .disabled })
        }
    }

    enum TrackingState {
        case disabled, enabled(isIndoor: Bool)
    }
}

#Preview {
    ContentView()
}
