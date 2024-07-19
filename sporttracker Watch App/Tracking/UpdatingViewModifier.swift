//
//  UpdatingViewModifier.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI

extension View {
    func updates(interval: Double, enabled: Bool = true, action: @escaping () -> ()) -> some View {
        Group {
            if enabled {
                self.modifier(UpdatingViewModifier(interval: interval, action: action))
            } else {
                self
            }
        }
    }
}

fileprivate struct UpdatingViewModifier: ViewModifier {
    var interval: Double
    var action: () -> ()
    @State private var timer: Timer? = nil

    func body(content: Content) -> some View {
        content
            .onAppear {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                    action()
                }
                action()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
}
