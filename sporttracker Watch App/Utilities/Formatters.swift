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
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let kilometers = meters / 1000.0
        return formatter.string(from: kilometers as NSNumber) ?? "\(kilometers)"
    }

    static func duration(_ seconds: Double) -> String {
        // TODO: probably wrong
        let wholeMinutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds - 60.0 * Double(wholeMinutes))

        return "\(wholeMinutes):\(remainingSeconds)"
    }

    static func heartRate(_ beatsPerMin: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter.string(from: beatsPerMin as NSNumber) ?? "\(beatsPerMin)"
    }
}
