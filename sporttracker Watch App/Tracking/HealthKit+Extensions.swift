//
//  HealthKit+Extensions.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import HealthKit

extension HKUnit {
    static func kilometerPerSecond() -> HKUnit {
        let secondUnit = HKUnit.second()
        let kilometerUnit = HKUnit.meterUnit(with: .kilo)
        return kilometerUnit.unitDivided(by: secondUnit)
    }

    static func countPerMinute() -> HKUnit {
        let countUnit = HKUnit.count()
        let minuteUnit = HKUnit.minute()
        return countUnit.unitDivided(by: minuteUnit)
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

extension Double {
    /// - Returns: One divided by the receiver, or zero if the receiver is zero.
    func inverse() -> Double {
        guard self != 0.0 else {
            return 0.0
        }
        return 1.0 / self
    }
}
