//
//  ContentView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct ContentView: View {
    @State var isTracking: Bool = false

    var body: some View {
        if isTracking {
            TrackingView(endTracking: { isTracking = false })
        } else {
            MenuView(startTracking: { isTracking = true })
        }
    }
}

#Preview {
    ContentView()
}
