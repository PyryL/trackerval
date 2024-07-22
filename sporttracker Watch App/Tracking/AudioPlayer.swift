//
//  AudioPlayer.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 22.7.2024.
//

import AVFoundation

class AudioPlayer {
    init() {
        do {
            let url = Bundle.main.url(forResource: "new-segment", withExtension: "wav")!
            newSegmentPlayer = try AVAudioPlayer(contentsOf: url)
            newSegmentPlayer?.prepareToPlay()
        } catch {
            print("new segment player failed", error)
            newSegmentPlayer = nil
        }

        setAudioSession()
    }

    private let newSegmentPlayer: AVAudioPlayer?

    private func setAudioSession() {
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

    func playNewSegment() {
        guard let player = newSegmentPlayer, !player.isPlaying else {
            return
        }

        player.play()
    }
}
