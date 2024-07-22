//
//  WorkoutPlotView.swift
//  sporttracker
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import SwiftUI
import HealthKit
import Charts

struct WorkoutPlotView: View {
    var sampleType: HKQuantityType
    var value: (HKQuantity) -> (Double)
    var segmentStart: Date
    var segmentEnd: Date
    var workout: HKWorkout
    var healthManager: HealthManager
    @State fileprivate var data: [PlotDataItem] = []

    fileprivate var segmentData: ArraySlice<PlotDataItem> {
        guard let startIndex = data.firstIndex(where: { $0.date >= segmentStart }),
              let endIndex = data.lastIndex(where: { $0.date <= segmentEnd }),
              startIndex < endIndex else {

            return []
        }

        return data[startIndex ... endIndex]
    }

    func loadData() async {
        do {
            let samples = try await healthManager.getData(sampleType, workout: workout)
            data = samples.map {
                PlotDataItem(date: $0.startDate, value: value($0.quantity))
            }
        } catch {
            print("failed to load heart rates", error)
        }
    }

    var body: some View {
        Group {
            if !segmentData.isEmpty {
                Chart(segmentData) {
                    LineMark(x: .value("Time", $0.date),
                             y: .value("Value", $0.value))
                }
                .chartXScale(domain: segmentStart ... segmentEnd)
                .chartYScale(domain: data.map { $0.value }.min()!*0.9 ... data.map { $0.value }.max()!*1.1)
            } else {
                Text("No data")
            }
        }
        .task {
            await loadData()
        }
    }
}

fileprivate struct PlotDataItem: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
}

//#Preview {
//    WorkoutPlotView()
//}
