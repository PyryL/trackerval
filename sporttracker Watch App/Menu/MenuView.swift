//
//  MenuView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct MenuView: View {
    var startTracking: () -> ()

    var body: some View {
        NavigationStack {
            Button(action: startTracking) {
                Label("Start tracking", systemImage: "figure.run")
            }
        }
    }
}

#Preview {
    MenuView(startTracking: { })
}
