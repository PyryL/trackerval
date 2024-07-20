//
//  Formatters.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.7.2024.
//

import Foundation

class Formatters {
    /// - Returns: The given meters converted to kilometers and formatted without unit.
    static func distance(_ meters: Double) -> String {
        guard meters >= 0.0 else {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let tensMeters = floor(meters / 10.0)
        let kilometers = tensMeters / 100.0
        return formatter.string(from: kilometers as NSNumber) ?? "\(kilometers)"
    }

    static func duration(_ seconds: Double, withFraction: Bool = true) -> String {
        // TODO: fix this
        let wholeMinutes = Int(seconds) / 60
        let remainingSeconds = seconds - 60.0 * Double(wholeMinutes)

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = withFraction ? 1 : 0
        formatter.maximumFractionDigits = withFraction ? 1 : 0
        formatter.decimalSeparator = "."
        let secondsString = formatter.string(from: remainingSeconds as NSNumber) ?? "\(remainingSeconds)"

        return "\(wholeMinutes):\(secondsString)"
    }

    static func heartRate(_ beatsPerMin: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter.string(from: beatsPerMin as NSNumber) ?? "\(beatsPerMin)"
    }
}
