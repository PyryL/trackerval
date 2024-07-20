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

    /// - Returns: The given seconds formatted into hours, minutes, seconds and tenths of seconds.
    ///     Hours and minutes are dropped if zero.
    static func duration(_ seconds: Double) -> String {
        guard seconds >= 0.0 else {
            return ""
        }

        let secondTenths: Int = Int(ceil(10.0 * seconds))

        let wholeHours: Int = secondTenths / 36000
        let wholeMinutes: Int = (secondTenths - 36000 * wholeHours) / 600
        let wholeSeconds: Int = (secondTenths - 36000 * wholeHours - 600 * wholeMinutes) / 10
        let fractionSecond: Int = secondTenths - 36000 * wholeHours - 600 * wholeMinutes - 10 * wholeSeconds

        let wholeMinuteString = String(format: wholeHours == 0 ? "%01d" : "%02d", wholeMinutes)
        let wholeSecondsString = String(format: "%02d", wholeSeconds)

        if wholeHours > 0 {
            return "\(wholeHours):\(wholeMinuteString):\(wholeSecondsString).\(fractionSecond)"
        }

        if wholeMinutes > 0 {
            return "\(wholeMinuteString):\(wholeSecondsString).\(fractionSecond)"
        }

        return "\(wholeSecondsString).\(fractionSecond)"
    }

    static func speed(_ secondsPerKm: Double) -> String {
        guard secondsPerKm >= 0.0 else {
            return ""
        }

        let seconds = Int(ceil(secondsPerKm))

        let wholeMinutes: Int = seconds / 60
        let remainingSeconds: Int = seconds - 60 * wholeMinutes

        let remainingSecondsString = String(format: "%02d", remainingSeconds)

        return "\(wholeMinutes):\(remainingSecondsString)"
    }

    static func heartRate(_ beatsPerMin: Double) -> String {
        guard beatsPerMin >= 0.0 else {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter.string(from: beatsPerMin as NSNumber) ?? "\(beatsPerMin)"
    }
}
