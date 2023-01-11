//
//  GoogleAPI+NearbySearchLocation.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import CoreLocation
import Foundation

// MARK: - Core Location Wrangling

extension GoogleAPI.NearbySearch {
    func verifyUserPermissionToAccessLocation() async throws {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            // We're good to get the location.
            break

        case .notDetermined:
            // Present user UI.
            let _: Void = await withCheckedContinuation { continuation in
                authRequestContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

            // Once we land here the auth status has changed, so let's try again.
            try await verifyUserPermissionToAccessLocation()

        case .denied, .restricted:
            // Seeing weird behavior with custom error types so throwing an NSError instead. Needs further research.
            let localizedDescription = errorMessageForCLAuthStatus(authStatus: locationManager.authorizationStatus)
            throw NSError(
                domain: GoogleAPI.ErrorDomain,
                code: 7777,
                userInfo: [NSLocalizedDescriptionKey: localizedDescription]
            )

        @unknown default:
            // Seeing weird behavior with custom error types so throwing an NSError instead. Needs further research.
            let localizedDescription = errorMessageForCLAuthStatus(authStatus: locationManager.authorizationStatus)
            throw NSError(
                domain: GoogleAPI.ErrorDomain,
                code: 7777,
                userInfo: [NSLocalizedDescriptionKey: localizedDescription]
            )
        }
    }

    func obtainCurrentLocation() async throws -> CLLocation {
        if let currentLocation = lastBestLocation {
            // No matter what make sure we'll be updating the location.
            locationManager.startUpdatingLocation()
            return currentLocation
        } else {
            // Wait for the delegate to get called (or fail) and then continue that.
            return try await withCheckedThrowingContinuation { continuation in
                currentLocationContinuation = continuation
                locationManager.startUpdatingLocation()
            }
        }
    }

    private func errorMessageForCLAuthStatus(authStatus: CLAuthorizationStatus) -> String {
        switch authStatus {
        case .denied:
            if CLLocationManager.locationServicesEnabled() {
                return "Please go to settings and authorize the application to access the current location."
            } else {
                return """
                Please reenable location services in settings and authorize the application to obtain the device \
                location.
                """
            }

        case .restricted:
            return """
             LunchQuest cannot use location services. Please contact your device's administrator to authorize \
             the app to do so.
            """

        default:
            return "Unable to obtain the user's location for mysterious reasons."
        }
    }
}

// MARK: - CLLocationManagerDelegate Adoption

extension GoogleAPI.NearbySearch: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager === locationManager else {
            fatalError()
        }

        guard let continuation = authRequestContinuation else {
            return
        }

        // Clean up to avoid extra calls to a continuation.
        authRequestContinuation = nil

        // We'll let the async logic take it from here (it will check the auth status again, just because it has changed
        // doesn't mean the user has authorized it).
        continuation.resume()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard manager === locationManager else {
            fatalError()
        }

        guard let continuation = currentLocationContinuation else {
            return
        }

        // Whatever happens we are going to call the continuation.
        currentLocationContinuation = nil

        guard let currentLocation = locations.last else {
            continuation.resume(throwing: NSError(
                domain: GoogleAPI.ErrorDomain,
                code: 7777,
                userInfo: [NSLocalizedDescriptionKey: "No locations obtained from core location"]
            ))
            return
        }

        lastBestLocation = currentLocation
        continuation.resume(returning: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard manager === locationManager else {
            fatalError()
        }

        guard let continuation = currentLocationContinuation else {
            return
        }

        // Whatever happens we are going to call the continuation.
        currentLocationContinuation = nil

        // Let's just pass the error down.
        continuation.resume(throwing: error)
    }
}
