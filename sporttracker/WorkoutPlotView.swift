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
    var valueGetter: (HKQuantity) -> (Double)
    var formatter: (Double) -> (String)
    var segmentStart: Date
    var segmentEnd: Date
    var workout: HKWorkout
    var healthManager: HealthManager
    @State fileprivate var data: [PlotDataItem] = []
    @State var average: Double? = nil
    @State var minimum: Double? = nil
    @State var maximum: Double? = nil

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
                PlotDataItem(date: $0.startDate, value: valueGetter($0.quantity))
            }
        } catch {
            print("failed to load heart rates", error)
        }
    }

    func loadStatistics() {
        Task {
            do {
                let statistics = try await healthManager.getStatistics(sampleType,
                                                                       startDate: segmentStart,
                                                                       endDate: segmentEnd,
                                                                       workout: workout)
                let averageQuantity = statistics.averageQuantity()
                let minimumQuantity = statistics.minimumQuantity()
                let maximumQuantity = statistics.maximumQuantity()

                let average = averageQuantity != nil ? valueGetter(averageQuantity!) : nil
                var minimum = minimumQuantity != nil ? valueGetter(minimumQuantity!) : nil
                var maximum = maximumQuantity != nil ? valueGetter(maximumQuantity!) : nil

                // the min and max values may be in wrong order e.g. when handling speed
                if minimum != nil, maximum != nil, maximum! < minimum! {
                    (minimum, maximum) = (maximum, minimum)
                }

                DispatchQueue.main.async {
                    self.average = average
                    self.minimum = minimum
                    self.maximum = maximum
                }
            } catch {
                print("failed to load statistics", error)
            }
        }
    }

    var keyValuesLabel: String {
        let averageString = average != nil ? formatter(average!) : "..."
        let minimumString = minimum != nil ? formatter(minimum!) : "..."
        let maximumString = maximum != nil ? formatter(maximum!) : "..."

        return "Average: \(averageString) (\(minimumString)-\(maximumString))"
    }

    var body: some View {
        VStack(spacing: 0) {
            if !segmentData.isEmpty {
                HStack {
                    Text(keyValuesLabel)
                        .font(.caption)
                    Spacer()
                }

                Chart(segmentData) {
                    LineMark(x: .value("Time", $0.date),
                             y: .value("Value", $0.value))
                }
                .chartXScale(domain: segmentStart ... segmentEnd)
                .chartYScale(domain: data.map { $0.value }.min()!*0.9 ... data.map { $0.value }.max()!*1.1)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text(formatter(value.as(Double.self)!))
                        }
                    }
                }
            } else {
                Text("No data")
            }
        }
        .task {
            await loadData()
        }
        .onAppear(perform: loadStatistics)
        .onChange(of: segmentStart, loadStatistics)
        .onChange(of: segmentEnd, loadStatistics)
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
