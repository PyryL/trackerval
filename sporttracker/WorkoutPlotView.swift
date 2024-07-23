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
    var systemImage: String
    @Binding var inspectorDate: Date?
    var segmentStart: Date
    var segmentEnd: Date
    var workout: HKWorkout
    var healthManager: HealthManager
    @State fileprivate var data: [PlotDataItem] = []
    @State fileprivate var inspectorValues: (PlotDataItem, PlotDataItem)? = nil
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

    fileprivate func updateInspectorValues() {
        guard let inspectorDate,
              !segmentData.isEmpty,
              segmentData.first!.date < inspectorDate,
              segmentData.last!.date > inspectorDate else {

            inspectorValues = nil
            return
        }

        let maxIndex = segmentData.index(before: segmentData.endIndex)

        var left = segmentData.startIndex
        var right = maxIndex

        while left < right {
            let mid = (left + right) / 2

            if segmentData[mid].date == inspectorDate {
                inspectorValues = (segmentData[mid], segmentData[mid])
                return
            } else if segmentData[mid].date < inspectorDate {
                left = min(mid+1, maxIndex)
            } else {
                right = max(mid-1, segmentData.startIndex)
            }
        }

        inspectorValues = (segmentData[right], segmentData[left])
    }

    var yScale: ClosedRange<Double> {
        guard let minValue = segmentData.map({ $0.value }).min(),
              let maxValue = segmentData.map({ $0.value }).max() else {

            return 0.0 ... 1.0
        }

        return (0.95 * minValue) ... (1.05 * maxValue)
    }

    var keyValuesLabel: String {
        if let inspectorValues {
            let startString = formatter(inspectorValues.0.value)
            let endString = formatter(inspectorValues.1.value)
            if startString == endString {
                return startString
            }
            return "\(startString)-\(endString)"
        }

        let averageString = average != nil ? formatter(average!) : "..."
        let minimumString = minimum != nil ? formatter(minimum!) : "..."
        let maximumString = maximum != nil ? formatter(maximum!) : "..."

        return "Average: \(averageString) (\(minimumString)-\(maximumString))"
    }

    var body: some View {
        VStack(spacing: 0) {
            if !segmentData.isEmpty {
                HStack {
                    Image(systemName: systemImage)
                    Text(keyValuesLabel)
                    Spacer()
                }
                .font(.caption)

                Chart(segmentData) {
                    LineMark(x: .value("Time", $0.date),
                             y: .value("Value", $0.value))

                    if let inspectorValues {
                        PointMark(x: .value("Selection time", inspectorValues.0.date),
                                  y: .value("Selection value", inspectorValues.0.value))
                    }
                }
                .chartXScale(domain: segmentStart ... segmentEnd)
                .chartYScale(domain: yScale)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text(formatter(value.as(Double.self)!))
                        }
                        AxisGridLine()
                    }
                }
                .modifier(PlotGestureModifier(inspectorDate: $inspectorDate))
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
        .onChange(of: inspectorDate, updateInspectorValues)
    }
}

fileprivate struct PlotGestureModifier: ViewModifier {
    @Binding var inspectorDate: Date?

    func body(content: Content) -> some View {
        content.chartGesture { chart in
            DragGesture(minimumDistance: 30.0)
                .onChanged { gesture in
                    guard let chartValues = chart.value(at: gesture.location, as: (Date, Double).self) else {
                        return
                    }
                    inspectorDate = chartValues.0
                }
                .onEnded { _ in
                    inspectorDate = nil
                }
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
