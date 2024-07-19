//
//  TrackingMenu.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct TrackingMenu: View {
    @ObservedObject var trackingManager: TrackingManager
    var closeMenu: () -> ()

    var body: some View {
        NavigationStack {
            // TODO: implement all actions
            List {
                NavigationLink {
                    intervalPreparationView
                } label: {
                    Label("Prepare for interval", systemImage: "flag")
                }

                Button(action: { }) {
                    Label("New segment", systemImage: "arrow.triangle.capsulepath")
                }

                Button(action: { }) {
                    Label("End workout", systemImage: "xmark")
                }
            }
        }
    }

    private var intervalPreparationView: some View {
        List {
            // TODO: implement pacer
            Text("Pacer: Off")

            Button {
                trackingManager.intervalStatus = .preparedForInterval
                closeMenu()
            } label: {
                Label("Activate", systemImage: "flag")
            }
        }
    }
}

#Preview {
    let trackingManager = TrackingManager()
    return TrackingMenu(trackingManager: trackingManager, closeMenu: { })
}
