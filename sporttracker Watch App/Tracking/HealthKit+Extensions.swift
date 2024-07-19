//
//  HealthKit+Extensions.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import HealthKit

extension HKUnit {
    static func kilometerPerMinute() -> HKUnit {
        let minuteUnit = HKUnit.minute()
        let kilometerUnit = HKUnit.meterUnit(with: .kilo)
        return kilometerUnit.unitDivided(by: minuteUnit)
    }
}

extension HKWorkoutSessionState {
    var description: String {
        switch self {
        case .notStarted:
            return "notStarted"
        case .running:
            return "running"
        case .ended:
            return "ended"
        case .paused:
            return "paused"
        case .prepared:
            return "prepared"
        case .stopped:
            return "stopped"
        @unknown default:
            return "unknown"
        }
    }
}
