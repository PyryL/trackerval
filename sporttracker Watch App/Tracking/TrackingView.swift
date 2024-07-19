//
//  TrackingView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct TrackingView: View {
    @StateObject var trackingManager = TrackingManager()
    @State var showMenu: Bool = false
    @State var currentParameterViewDuration: String = ""

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
        Group {
            if trackingManager.intervalStatus == .disabled {
                NavigationStack {
                    TabView {
                        currentParametersView
                        detailedParametersView
                    }
                    .tabViewStyle(.verticalPage)
                }
            } else {
                currentParametersView
                    .modifier(QuickSegmentingModifier(action: trackingManager.addSegment))
            }
        }
    }

    private var currentParametersView: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
            }
            Text(currentParameterViewDuration)
                .updates(interval: 0.05) {
                    guard let date = trackingManager.segmentDates.last ?? trackingManager.startDate else {
                        return
                    }
                    currentParameterViewDuration = Formatters.duration(-date.timeIntervalSinceNow)
                }
            Text(Formatters.duration(trackingManager.currentSpeed, withFraction: false) + " /km")
            Text(Formatters.heartRate(trackingManager.currentHeartRate) + " bpm")
            if trackingManager.intervalStatus != .disabled {
                HStack {
                    Spacer()
                    Image(systemName: "flag")
                    Text(trackingManager.intervalStatus == .preparedForInterval ? "Prepared for interval" : "Interval")
                    Spacer()
                }
                .font(.footnote)
                .foregroundStyle(trackingManager.intervalStatus == .preparedForInterval ? .blue : .orange)
            }
        }
        .lineLimit(1)
        .font(.system(size: 99, weight: .semibold, design: .rounded))
        .minimumScaleFactor(0.1)
        .background()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showMenu = true }) {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showMenu) {
            TrackingMenu(trackingManager: trackingManager, closeMenu: { showMenu = false })
        }
    }

    private var detailedParametersView: some View {
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

    private var startingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(.circular)
                .fixedSize(horizontal: true, vertical: true)
            Text("Starting...")
        }
    }

    private struct QuickSegmentingModifier: ViewModifier {
        var action: () -> () = { print("segment") }
        @State private var dragTriggered: Bool = false

        func body(content: Content) -> some View {
            content
                .onTapGesture(perform: action)
                .gesture(DragGesture(minimumDistance: 0)
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
//    trackingManager.intervalStatus = .preparedForInterval
    return TrackingView(trackingManager: trackingManager)
}
