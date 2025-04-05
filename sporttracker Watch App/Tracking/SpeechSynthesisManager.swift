//
//  SpeechSynthesisManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 23.3.2025.
//

import Foundation
import AVFoundation

class SpeechSynthesisManager {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(result: Double) {
        guard !synthesizer.isSpeaking else {
            print("synthesis already speaking")
            return
        }

        let text = SpeechSynthesisManager.format(result: result)
        let utterance = AVSpeechUtterance(string: text)

        utterance.voice = selectVoice()
        utterance.rate = min(1.15 * AVSpeechUtteranceDefaultSpeechRate, AVSpeechUtteranceMaximumSpeechRate)

        synthesizer.speak(utterance)
    }

    private func selectVoice() -> AVSpeechSynthesisVoice {
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().hasPrefix("en") && !$0.voiceTraits.contains(.isPersonalVoice)
        }

        guard !englishVoices.isEmpty else {
            return AVSpeechSynthesisVoice()
        }

        for quality: AVSpeechSynthesisVoiceQuality in [.premium, .enhanced, .default] {
            let qualityVoices = englishVoices.filter { $0.quality == quality }

            guard !qualityVoices.isEmpty else {
                continue
            }

            if let maleVoice = qualityVoices.first(where: { $0.gender == .male }) {
                return maleVoice
            }
            return qualityVoices.first!
        }

        return AVSpeechSynthesisVoice()
    }

    /// Converts the given result into a string that looks ugly but sounds good when spoken aloud.
    static func format(result: Double) -> String {
        // written format is something like "4.6", "58.2", "1:01.6", "11:22.4", or "2:39:16.9"
        let writtenFormat = Formatters.duration(result)

        let decimalParts = writtenFormat.split(separator: ".")

        guard decimalParts.count == 2 else {
            // may end up in here in some rare occasions
            return writtenFormat
        }

        // for each part before fraction dot replace the leading zero with "oh-"
        // for example "5:02.0" -> "5 oh-2 0" and "1:00.0" -> "1 00 0"

        let ohParts = decimalParts[0].split(separator: ":").map {
            if $0.count == 2 {
                let firstChar = $0[$0.startIndex]
                let secondChar = $0[$0.index(after: $0.startIndex)]

                if firstChar == "0", secondChar != "0" {
                    return "oh-" + String(secondChar)
                }
            }
            return String($0)
        }

        let finalParts = ohParts + [String(decimalParts[1])]

        return finalParts.joined(separator: " ")
    }
}
