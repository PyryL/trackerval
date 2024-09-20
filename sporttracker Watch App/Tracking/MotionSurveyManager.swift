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

    func markIntervalStart(date: Date) {
        recording?.intervalStart = date.timeIntervalSince1970
    }

    func stopRecording() {
        isRecording = false
        MotionStartManager.manager.stopDeviceMotionUpdates()

        guard let recording else {
            return
        }

        do {
            try MotionSurveyRepository().save(recording)
        } catch {
            print("failed to save motion survey recording", error)
        }

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
            recording = MotionSurveyRecording(
                firstFrameDate: Date.now.timeIntervalSince1970,
                intervalStart: -1.0,
                frames: [])
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

class MotionSurveyRepository {
    init() {
        directory = URL.applicationSupportDirectory.appending(component: "motion-survey", directoryHint: .isDirectory)
    }

    private let directory: URL

    fileprivate func save(_ recording: MotionSurveyRecording) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let dateString = Date(timeIntervalSince1970: recording.firstFrameDate).ISO8601Format()
        let fileURL = directory.appendingPathComponent("recording-\(dateString).json")

        try JSONEncoder().encode(recording).write(to: fileURL)
    }

    func listFiles() throws -> [RepositoryFile] {
        guard FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) else {
            return []
        }

        let fileUrls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.totalFileSizeKey])

        return fileUrls.map {
            let filename = $0.lastPathComponent

            var date: Date? = nil
            var fileSize: Int? = nil

            if filename.hasPrefix("recording-"), filename.hasSuffix(".json") {
                let dateString = filename
                    .replacingOccurrences(of: "recording-", with: "")
                    .replacingOccurrences(of: ".json", with: "")

                date = ISO8601DateFormatter().date(from: dateString)
            }

            if let resourceValues = try? $0.resourceValues(forKeys: [.totalFileSizeKey]) {
                fileSize = resourceValues.totalFileSize
            }

            return RepositoryFile(date: date, fileSize: fileSize, url: $0)
        }
    }

    struct RepositoryFile: Hashable {
        var date: Date?
        var fileSize: Int?
        var url: URL
    }
}

fileprivate struct MotionSurveyRecording: Encodable {
    let version: Int = 1
    var firstFrameDate: Double
    var intervalStart: Double
    var frames: [[Double]]
}
