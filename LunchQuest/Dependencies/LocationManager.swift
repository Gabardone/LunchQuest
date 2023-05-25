//
//  LocationManager.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/20/23.
//

import Combine
import CoreLocation
import Foundation
import MiniDePin
import SwiftUX

enum TrackedLocation {
    /**
     The current location remains unknown. Either it has not been requested yet or it has not been returned yet.

     If the location manager requests the location and the operation fails you will see `failure(error)` instead.
     */
    case unknown

    /**
     The location has been found, the associated value is the last update.
     */
    case located(CLLocation)

    /**
     There was a failure obtaining the location. The associated value is the proximate error that caused the failure.
     */
    case failure(Error)
}

extension TrackedLocation: Equatable {
    static func == (lhs: TrackedLocation, rhs: TrackedLocation) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true

        case let (.located(lhsLocation), .located(rhsLocation)):
            return lhsLocation == rhsLocation

        default:
            return false
        }
    }
}

/**
 A façade protocol for the system's location manager.

 As it exists, `CLLocationManager` introduces a hard dependency that gets in the way of making location-using logic
 testable. This protocol is used to wrap the parts of its functionality needed by the app, while allowing for an easy
 build of a testing mock.
 */
protocol LocationManager {
    /**
     A `Property` that manages the current authorization status and publishes its updates.
     */
    var authorizationStatus: any Property<CLAuthorizationStatus> { get }

    /**
     A `Property` that manages the last returned device location. May be `nil` if it is unavailable so far.
     */
    var currentLocation: any Property<TrackedLocation> { get }

    /**
     Façade for the `CLLocationManager` API of the same name.
     */
    func requestWhenInUseAuthorization()

    /**
     Façade for the `CLLocationManager` API of the same name.
     */
    func startUpdatingLocation()

    /**
     Façade for the `CLLocationManager` API of the same name.
     */
    func stopUpdatingLocation()
}

protocol LocationDependency: Dependencies {
    var locationManager: any LocationManager { get }
}

extension GlobalDependencies: LocationDependency {
    private static let systemLocationManager: any LocationManager = SystemLocationManager()

    var locationManager: any LocationManager {
        resolveDependency(forKeyPath: \.locationManager, defaultImplementation: Self.systemLocationManager)
    }
}

/**
 A wrapper for the system's location manager.

 While the basic access and request methods of `CLLocationManager` don't need wrapping, the delegate methods are harder
 to façade properly. Since almost all `CLLocationManagerDelegate` methods are purely reactive and the one that isn't we
 don't need, we reduce the dependency surface of the protocol façade by translating the delegate methods into combine
 subscriptions.
 */
class SystemLocationManager: NSObject {
    override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatusSubject = .init(locationManager.authorizationStatus)
        self.authorizationStatusProperty = .init(
            updates: authorizationStatusSubject.removeDuplicates().dropFirst(),
            getter: { [authorizationStatusSubject] in
                return authorizationStatusSubject.value
            }
        )
        self.currentLocationProperty = .init(
            updates: currentLocationSubject.removeDuplicates().dropFirst(),
            getter: { [currentLocationSubject] in
                currentLocationSubject.value
            })

        super.init()

        locationManager.delegate = self
    }

    private let runLoop = RunLoop.current

    private let locationManager: CLLocationManager

    private let authorizationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>

    private let authorizationStatusProperty: ReadOnlyProperty<CLAuthorizationStatus>

    private let currentLocationSubject = CurrentValueSubject<TrackedLocation, Never>(.unknown)

    private let currentLocationProperty: ReadOnlyProperty<TrackedLocation>
}

// MARK: - LocationManager Adoption

extension SystemLocationManager: LocationManager {
    var authorizationStatus: any Property<CLAuthorizationStatus> {
        authorizationStatusProperty
    }

    var currentLocation: any Property<TrackedLocation> {
        currentLocationProperty
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - Private CLLocationManagerDelegate Adoption.

extension SystemLocationManager: CLLocationManagerDelegate {
    @MainActor
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        assert(
            manager == locationManager,
            "`CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)` from unexpected object \(manager)"
        )

        // Update the storage.
        authorizationStatusSubject.send(manager.authorizationStatus)
    }

    @MainActor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        assert(
            manager == locationManager,
            "`CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)` from unexpected object \(manager)"
        )

        // Update the current location.
        guard let lastLocation = locations.last else {
            return
        }

        currentLocationSubject.send(.located(lastLocation))
    }

    @MainActor
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard manager === locationManager else {
            fatalError()
        }

        currentLocationSubject.send(.failure(error))
    }
}
