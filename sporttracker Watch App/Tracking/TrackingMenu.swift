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

    var isStatusEnding: Bool {
        if case .ending = trackingManager.status {
            return true
        }
        return false
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    IntervalPreparationView(trackingManager: trackingManager, closeMenu: closeMenu)
                } label: {
                    Label("Prepare for interval", systemImage: "flag")
                }

                Button {
                    trackingManager.addSegment(source: .trackingMenuButton)
                    closeMenu()
                } label: {
                    Label {
                        Text("New segment")
                    } icon: {
                        Image(systemName: "arrow.triangle.capsulepath")
                            .scaleEffect(y: -1.0)
                    }
                }

                Button(action: { showEndWorkoutAlert = true }) {
                    Label {
                        Text("End workout")
                    } icon: {
                        Group {
                            if isStatusEnding {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
                .disabled(isStatusEnding)
                .alert("End workout?", isPresented: $showEndWorkoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("End", role: .destructive) {
                        trackingManager.endWorkout()
                    }
                }
            }
        }
    }
}

fileprivate struct IntervalPreparationView: View {
    @ObservedObject var trackingManager: TrackingManager
    var closeMenu: () -> ()
    @State var pacerInputDigits: [String] = []

    private var pacerIntervalString: String {
        guard let interval = trackingManager.pacerInterval else {
            return "Off"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter.string(from: interval as NSNumber) ?? "\(interval)"
    }

    var body: some View {
        List {
            Button {
                guard case .running = trackingManager.status,
                      trackingManager.intervalStatus == .disabled else {

                    return
                }
                trackingManager.intervalStatus = .preparedForInterval
                trackingManager.motionSurveyManager.startRecording()
                closeMenu()
            } label: {
                Label("Activate", systemImage: "flag")
            }

            NavigationLink {
                pacerSettingView
            } label: {
                Label("Pacer: \(pacerIntervalString)", systemImage: "gauge.with.needle")
            }

            Toggle(isOn: $trackingManager.motionStartEnabled) {
                Label("Motion start", systemImage: "gyroscope")
            }
        }
    }

    private var pacerSettingView: some View {
        VStack(spacing: 1) {
            HStack {
                Spacer()
                Text(pacerInputDigits.joined())
                    .font(.headline.monospaced())
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.1)
                    .padding(.trailing)
            }
            HStack(spacing: 1) {
                KeyboardButton(digit: "1", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "2", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "3", pacerInputDigits: $pacerInputDigits)
            }
            HStack(spacing: 1) {
                KeyboardButton(digit: "4", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "5", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "6", pacerInputDigits: $pacerInputDigits)
            }
            HStack(spacing: 1) {
                KeyboardButton(digit: "7", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "8", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "9", pacerInputDigits: $pacerInputDigits)
            }
            HStack(spacing: 1) {
                KeyboardButton(digit: ".", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(digit: "0", pacerInputDigits: $pacerInputDigits)
                KeyboardButton(systemImage: "delete.left") { let _ = pacerInputDigits.popLast() }
            }
        }
        .onAppear {
            guard let interval = trackingManager.pacerInterval else {
                pacerInputDigits = []
                return
            }
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.decimalSeparator = "."
            formatter.maximumFractionDigits = 2
            guard let string = formatter.string(from: interval as NSNumber) else {
                return
            }
            pacerInputDigits = string.map { String($0) }
        }
        .onDisappear {
            guard !pacerInputDigits.isEmpty else {
                trackingManager.pacerInterval = nil
                return
            }
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.decimalSeparator = "."
            formatter.maximumFractionDigits = 2
            guard let interval = formatter.number(from: pacerInputDigits.joined()) as? Double else {
                return
            }
            trackingManager.pacerInterval = interval
        }
    }

    private struct KeyboardButton: View {
        init(digit: String, pacerInputDigits: Binding<[String]>) {
            self.digit = digit
            self._pacerInputDigits = pacerInputDigits
            self.action = nil
            self.systemImage = nil
        }

        init(systemImage: String, action: @escaping () -> ()) {
            self.systemImage = systemImage
            self.action = action
            self.digit = nil
            self._pacerInputDigits = .init(get: { [] }, set: { _ in })
        }

        var digit: String?
        var systemImage: String?
        var action: Optional<() -> ()>
        @Binding var pacerInputDigits: [String]

        private var fractionDigitCount: Int {
            guard let decimalSeparator = pacerInputDigits.firstIndex(of: ".") else {
                return 0
            }
            return pacerInputDigits.distance(from: decimalSeparator, to: pacerInputDigits.endIndex) - 1
        }

        var body: some View {
            Button {
                if let digit {
                    pacerInputDigits.append(digit)
                } else if let action {
                    action()
                }
            } label: {
                label
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill, ignoresSafeAreaEdges: [])
            }
            .buttonStyle(.plain)
            .disabled(fractionDigitCount >= 2)
        }

        private var label: some View {
            Group {
                if let digit {
                    Text(digit)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
            }
        }
    }
}

#Preview {
    let trackingManager = TrackingManager(endTracking: { })
    trackingManager.pacerInterval = 12.9122
    return TrackingMenu(trackingManager: trackingManager, closeMenu: { })
}
