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

    typealias AuthorizationCallback = (Bool, Error?) -> ()
    typealias LocationUpdateCallback = ([CLLocation]) -> ()

    private let manager = CLLocationManager()

    private var authorizationCallback: AuthorizationCallback? = nil
    private var locationUpdateCallback: LocationUpdateCallback? = nil

    func requestAuthorization() async throws {
        let _: Bool = try await withUnsafeThrowingContinuation { continuation in
            requestAuthorization { isGranted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }

    func requestAuthorization(_ callback: @escaping AuthorizationCallback) {
        authorizationCallback = callback

        guard manager.authorizationStatus == .notDetermined else {
            handleAuthorizationChange()
            return
        }

        manager.requestWhenInUseAuthorization()
    }

    private func handleAuthorizationChange() {
        guard let authorizationCallback else {
            return
        }

        defer {
            self.authorizationCallback = nil
        }

        guard [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) else {
            authorizationCallback(false, LocationError.notGranted)
            return
        }

        guard manager.accuracyAuthorization == .fullAccuracy else {
            authorizationCallback(false, LocationError.reducedAccuracy)
            return
        }

        authorizationCallback(true, nil)
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

    enum LocationError: Error {
        case notGranted, reducedAccuracy
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange()
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

extension LocationManager.LocationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notGranted:
            "You have not granted permission to use location data."
        case .reducedAccuracy:
            "You have not granted permission to use accurate location data."
        }
    }
}
