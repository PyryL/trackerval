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
        .foregroundStyle(trackingManager.intervalStatus == .disabled ? Color("SportNeon") : .primary)
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
    return CurrentParametersView(trackingManager: trackingManager)
}
