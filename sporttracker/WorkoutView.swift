//
//  WorkoutView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import SwiftUI
import HealthKit

struct WorkoutView: View {
    var workout: HKWorkout

    var body: some View {
        Form {
            Text("workout here")
        }
        .navigationTitle(workout.startDate.formatted(date: .numeric, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    WorkoutView(workout: _)
//}
