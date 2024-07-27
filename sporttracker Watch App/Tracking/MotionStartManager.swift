//
//  MotionStartManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 26.7.2024.
//

import CoreMotion

class MotionStartManager {

    private let manager = CMMotionManager()

    var motionStartCallback: Optional<() -> ()> = nil

    func start() {
        manager.accelerometerUpdateInterval = 0.01
        manager.startAccelerometerUpdates(to: OperationQueue(), withHandler: receivedMotion)
    }

    func stop() {
        manager.stopAccelerometerUpdates()
    }

    private func receivedMotion(data: CMAccelerometerData?, error: Error?) {
        if let error {
            print("motion failed", error)
            return
        }

        guard let data else {
            fatalError()
        }

        let acceleration = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))

        if acceleration >= 3.0 {
            motionStartCallback?()
        }
    }
}
