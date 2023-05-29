//
//  GoogleAPI+NearbySearchLocation.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import Combine
import CoreLocation
import Foundation

// MARK: - Core Location Wrangling

extension GoogleAPI.NearbySearch {
    func verifyUserPermissionToAccessLocation() async throws {
        let locationManager = dependencies.locationManager
        switch locationManager.authorizationStatus.value {
        case .authorizedAlways, .authorizedWhenInUse:
            // We're good to get the location.
            break

        case .notDetermined:
            // Present user UI.
            let _: Void = await withCheckedContinuation { continuation in
                var subscription: AnyCancellable?
                subscription = dependencies.locationManager.authorizationStatus.updates.sink { _ in
                    subscription?.cancel()
                    continuation.resume()
                }
                dependencies.locationManager.requestWhenInUseAuthorization()
            }

            // Once we land here the auth status has changed, so let's try again.
            try await verifyUserPermissionToAccessLocation()

        case .denied, .restricted:
            // Seeing weird behavior with custom error types so throwing an NSError instead. Needs further research.
            let localizedDescription = errorMessageForCLAuthStatus(
                authStatus: locationManager.authorizationStatus.value
            )
            throw NSError(
                domain: GoogleAPI.ErrorDomain,
                code: 7777,
                userInfo: [NSLocalizedDescriptionKey: localizedDescription]
            )

        @unknown default:
            // Seeing weird behavior with custom error types so throwing an NSError instead. Needs further research.
            let localizedDescription = errorMessageForCLAuthStatus(
                authStatus: locationManager.authorizationStatus.value
            )
            throw NSError(
                domain: GoogleAPI.ErrorDomain,
                code: 7777,
                userInfo: [NSLocalizedDescriptionKey: localizedDescription]
            )
        }
    }

    func obtainCurrentLocation() async throws -> CLLocation {
        if case let .located(currentLocation) = dependencies.locationManager.currentLocation.value {
            // No matter what make sure we'll be updating the location.
            dependencies.locationManager.startUpdatingLocation()
            return currentLocation
        } else {
            // Wait for the delegate to get called (or fail) and then continue that.
            return try await withCheckedThrowingContinuation { continuation in
                var subscription: AnyCancellable?
                subscription = dependencies.locationManager.currentLocation.updates.sink { trackedLocation in
                    if case let .located(currentLocation) = trackedLocation {
                        subscription?.cancel()
                        continuation.resume(returning: currentLocation)
                    }
                }
                dependencies.locationManager.startUpdatingLocation()
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
