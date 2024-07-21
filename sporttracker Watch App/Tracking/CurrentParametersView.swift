//
//  CurrentParametersView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 20.7.2024.
//

import SwiftUI

struct CurrentParametersView: View {
    @ObservedObject var trackingManager: TrackingManager
    @State var showMenu: Bool = false
    @State var currentParameterViewDuration: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
            }
            ParameterView(value: currentParameterViewDuration, systemImage: "stopwatch")
                .updates(interval: 0.05) {
                    guard let date = trackingManager.segmentDates.last ?? trackingManager.startDate else {
                        return
                    }
                    currentParameterViewDuration = Formatters.duration(-date.timeIntervalSinceNow)
                }
            ParameterView(value: Formatters.speed(trackingManager.currentSpeed), systemImage: "speedometer")
            ParameterView(value: Formatters.heartRate(trackingManager.currentHeartRate), systemImage: "heart")
            if trackingManager.intervalStatus != .disabled {
                intervalModeLabel
            }
        }
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

    private var intervalModeLabel: some View {
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

fileprivate struct ParameterView: View {
    var value: String
    var systemImage: String

    var body: some View {
        Text(value)
            .lineLimit(1)
            .font(.system(size: 99, weight: .semibold, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.1)
            .padding(.leading, 20)
            .overlay(alignment: .leadingFirstTextBaseline) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color("SportNeon"))
            }
    }
}

#Preview {
    let trackingManager = TrackingManager(endTracking: { })
    trackingManager.isStarted = true
    trackingManager.startDate = Date(timeIntervalSinceNow: -758.1733) // 12:38
    trackingManager.segmentDates = [Date(timeIntervalSinceNow: -99.315)] // 1:39
    trackingManager.distance = 1912.156
    trackingManager.averageSpeed = 351 // 5:51
    trackingManager.currentSpeed = 344 // 5:44
    trackingManager.averageHeartRate = 128.419
    trackingManager.currentHeartRate = 135
    return CurrentParametersView(trackingManager: trackingManager)
}
