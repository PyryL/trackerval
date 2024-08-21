//
//  AudioPlayer.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import AVFoundation

class AudioPlayer {
    init(sound: Sound) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: sound.url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("new segment player failed", error)
            audioPlayer = nil
        }
    }

    private let audioPlayer: AVAudioPlayer?

    static func setAudioSession() {
        do {
            var options: AVAudioSession.CategoryOptions = .duckOthers
            if #available(watchOS 11.0, *) {
                options.insert(.allowBluetooth)
            }
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: options)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("audio session failed", error)
        }
    }

    static func unsetAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("audio session unset failed", error)
        }
    }

    func play() {
        guard let player = audioPlayer, !player.isPlaying else {
            return
        }

        player.play()
    }

    enum Sound {
        case newSegment, pacer

        var url: URL {
            switch self {
            case .newSegment:
                Bundle.main.url(forResource: "new-segment", withExtension: "wav")!
            case .pacer:
                Bundle.main.url(forResource: "pacer", withExtension: "wav")!
            }
        }
    }
}
