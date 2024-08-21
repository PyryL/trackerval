//
//  MenuView.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

struct MenuView: View {
    var startTracking: () -> ()
    @State var showsInfo: Bool = false

    var body: some View {
        NavigationStack {
            // TODO: implement activity types
            Button(action: { }) {
                Label("Outdoor run", systemImage: "figure.run")
            }

            Button(action: startTracking) {
                Label("Start tracking", systemImage: "play")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showsInfo = true }) {
                        Label("Show info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showsInfo) {
                InfoView()
            }
        }
    }
}

fileprivate struct InfoView: View {
    private var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        var result = "Version "
        result += version ?? "x.x"
        result += " (" + (buildNumber ?? "x") + ")"

        if isDebug {
            result += ", debug"
        }

        return result
    }

    var body: some View {
        Form {
            Section(header: Text("About"), footer: Text(appVersionLabel)) {
                Label("Pyry Lahtinen / WinterFog", systemImage: "person")
                    .bold()
            }
        }
    }
}

#Preview {
    MenuView(startTracking: { })
}
