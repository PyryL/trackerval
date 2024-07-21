//
//  LocationManager.swift
//  sporttracker Watch App
//
//  Created by Pyry Lahtinen on 21.7.2024.
//

import CoreLocation

class LocationManager: NSObject {
    override init() {
        super.init()
        manager.delegate = self
    }

    typealias LocationUpdateCallback = ([CLLocation]) -> ()

    private let manager = CLLocationManager()

    private var authorizationCallback: Optional<() -> ()> = nil
    private var locationUpdateCallback: LocationUpdateCallback? = nil

    func requestAuthorization() async {
        await withUnsafeContinuation { continuation in
            requestAuthorization {
                continuation.resume()
            }
        }
    }

    func requestAuthorization(_ callback: @escaping () -> ()) {
        guard manager.authorizationStatus == .notDetermined else {
            callback()
            return
        }

        authorizationCallback = callback
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating(_ handler: @escaping LocationUpdateCallback) {
        locationUpdateCallback = handler
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationUpdateCallback = nil
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        guard [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus),
              manager.accuracyAuthorization == .fullAccuracy else {
            return
        }

        authorizationCallback?()
        authorizationCallback = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let accurateLocations = locations.filter {
            $0.horizontalAccuracy <= 30.0
        }

        guard !accurateLocations.isEmpty else {
            return
        }

        locationUpdateCallback?(accurateLocations)
    }
}
