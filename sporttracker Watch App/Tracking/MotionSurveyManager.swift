//
//  MotionSurveyManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 19.9.2024.
//

import CoreMotion

class MotionSurveyManager {

    private var isRecording: Bool = false
    private var recording: MotionSurveyRecording? = nil

    func startRecording() {
        guard !isRecording, recording == nil else {
            return
        }

        isRecording = true
        MotionStartManager.manager.deviceMotionUpdateInterval = 0.01
        MotionStartManager.manager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: receivedMotionData)
    }

    func stopRecording() {
        isRecording = false
        MotionStartManager.manager.stopDeviceMotionUpdates()

        guard let recording else {
            return
        }

        // TODO: save to file

        let fileContent = try! JSONEncoder().encode(recording)
        print("motion file", fileContent.count, recording.frames.count)
        print(String(data: fileContent, encoding: .utf8)?.prefix(100) as Any)

        self.recording = nil
    }

    private func receivedMotionData(_ motionData: CMDeviceMotion?, error: Error?) {
        if let error {
            print("motion survey failed", error)
            return
        }

        guard let motionData, isRecording else {
            return
        }

        if recording == nil {
            recording = MotionSurveyRecording(firstFrameDate: Date.now.timeIntervalSince1970, frames: [])
        }

        recording!.frames.append([
            motionData.timestamp,
            motionData.attitude.roll,
            motionData.attitude.pitch,
            motionData.attitude.yaw,
            motionData.userAcceleration.x,
            motionData.userAcceleration.y,
            motionData.userAcceleration.z,
            motionData.rotationRate.x,
            motionData.rotationRate.y,
            motionData.rotationRate.z,
        ])
    }
}

fileprivate struct MotionSurveyRecording: Encodable {
    let version: Int = 1
    var firstFrameDate: Double
    var frames: [[Double]]
}
