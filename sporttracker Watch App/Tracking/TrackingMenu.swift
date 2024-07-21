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
    @State var showEndWorkoutAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    intervalPreparationView
                } label: {
                    Label("Prepare for interval", systemImage: "flag")
                }

                Button {
                    trackingManager.addSegment()
                    closeMenu()
                } label: {
                    Label("New segment", systemImage: "arrow.triangle.capsulepath")
                }

                Button(action: { showEndWorkoutAlert = true }) {
                    Label {
                        Text("End workout")
                    } icon: {
                        Group {
                            if trackingManager.status != .ending {
                                Image(systemName: "xmark")
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                }
                .alert("End workout?", isPresented: $showEndWorkoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("End", role: .destructive) {
                        Task {
                            await trackingManager.endWorkout()
                        }
                    }
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
    let trackingManager = TrackingManager(endTracking: { })
    return TrackingMenu(trackingManager: trackingManager, closeMenu: { })
}
