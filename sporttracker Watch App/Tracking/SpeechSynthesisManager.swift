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

    private static func format(result: Double) -> String {
        // written format is something like "58.2", "11:22.4", or "2:39:16.9"
        let writtenFormat = Formatters.duration(result)

        // replace punctuation with spaces to make it read the numbers separately out loud
        // e.g. "fiftyeight two" or "eleven twenty-two four"
        return writtenFormat
            .replacing(".", with: " ")
            .replacing(":", with: " ")
    }
}
