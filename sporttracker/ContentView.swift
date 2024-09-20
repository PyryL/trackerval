//
//  ContentView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let watchConnection = WatchConnectionManager()
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

    func workoutSubtitle(_ workout: HKWorkout) -> String {
        Formatters.duration(workout.duration)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts, id: \.self) { workout in
                    NavigationLink(value: workout) {
                        VStack(alignment: .leading) {
                            Text(workoutTitle(workout))
                                .font(.headline)
                            Text(workoutSubtitle(workout))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: HKWorkout.self) { workout in
                WorkoutView(workout: workout, healthManager: healthManager)
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
