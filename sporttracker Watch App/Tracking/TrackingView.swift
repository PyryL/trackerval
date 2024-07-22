//
//  TrackingView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct TrackingView: View {
    init(trackingManager: TrackingManager? = nil, endTracking: @escaping () -> ()) {
        let trackingManager = trackingManager ?? TrackingManager(endTracking: endTracking)
        self._trackingManager = .init(wrappedValue: trackingManager)
        currentParametersView = CurrentParametersView(trackingManager: trackingManager)
    }

    @StateObject var trackingManager: TrackingManager
    let currentParametersView: CurrentParametersView

    var body: some View {
        Group {
            switch trackingManager.status {
            case .notStarted, .starting:
                startingView
            case .running, .ending:
                activeTrackingView
            case .failed(let error):
                failedView(error: error)
            }
        }
        .onAppear(perform: trackingManager.startWorkout)
    }

    private var activeTrackingView: some View {
        Group {
            if trackingManager.intervalStatus == .disabled {
                NavigationStack {
                    TabView {
                        currentParametersView
                        DetailedParametersView(trackingManager: trackingManager)
                    }
                    .tabViewStyle(.verticalPage)
                }
            } else {
                currentParametersView
                    .modifier(QuickSegmentingModifier(action: trackingManager.addSegment))
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

    private func failedView(error: Error) -> some View {
        ScrollView {
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Workout failed")
                    .font(.headline)

                if let userError = error as? LocalizedError,
                   let description = userError.errorDescription ?? userError.recoverySuggestion {
                    Text(description)
                        .multilineTextAlignment(.center)
                }

                Button("Back to menu") {
                    trackingManager.quitToMenu()
                }
            }
        }
    }

    private struct QuickSegmentingModifier: ViewModifier {
        var action: () -> ()
        @State private var pressTriggered: Bool = false
        @State private var dragTriggered: Bool = false

        func body(content: Content) -> some View {
            content
                .gesture(LongPressGesture(minimumDuration: .leastNormalMagnitude, maximumDistance: .greatestFiniteMagnitude)
                    .onChanged { isPressed in
                        guard isPressed, !pressTriggered else { return }
                        pressTriggered = true
                        action()
                    }
                    .onEnded { _ in
                        pressTriggered = false
                    })
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !dragTriggered else { return }
                        dragTriggered = true
                        action()
                    }
                    .onEnded { _ in
                        dragTriggered = false
                    })
        }
    }
}

#Preview {
    let trackingManager = TrackingManager(endTracking: { })
    trackingManager.status = .running
//    trackingManager.status = .failed(LocationManager.LocationError.reducedAccuracy)
    trackingManager.startDate = Date(timeIntervalSinceNow: -758.1733) // 12:38
    trackingManager.segmentDates = [Date(timeIntervalSinceNow: -99.315)] // 1:39
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 351 // 5:51
    trackingManager.currentSpeed = 344 // 5:44
    trackingManager.averageHeartRate = 128.419
    trackingManager.currentHeartRate = 135
//    trackingManager.intervalStatus = .preparedForInterval
    return TrackingView(trackingManager: trackingManager, endTracking: { })
}
