//
//  ContentView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthManager = HealthManager()
    @State var workouts: [HKWorkout] = []

    func workoutTitle(_ workout: HKWorkout) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .listItem
        return formatter.string(from: workout.startDate)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts, id: \.self) { workout in
                    NavigationLink(value: workout) {
                        Text(workoutTitle(workout))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: HKWorkout.self) { workout in
                WorkoutView(workout: workout)
            }
        }
        .task {
            do {
                try await healthManager.requestAuthorization()
                let workouts = try await healthManager.getWorkouts()
                DispatchQueue.main.async {
                    self.workouts = workouts
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
