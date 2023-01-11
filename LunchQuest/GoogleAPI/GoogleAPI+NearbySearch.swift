//
//  GoogleAPI+NearbySearch.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/15/23.
//

import CoreLocation
import Foundation
import MiniDePin

extension GoogleAPI {
    static let commonNearbySearchComponents: URLComponents = {
        var commonNearbySearchComponents = GoogleAPI.commonURLComponents
        commonNearbySearchComponents.path.append("/nearbysearch/json")
        commonNearbySearchComponents.queryItems?.append(contentsOf: [
            .init(name: "type", value: "restaurant"),
            .init(name: "radius", value: "16000") // Around 10 miles. Hardcoded for now.
        ])
        return commonNearbySearchComponents
    }()

    /**
     A class that runs the nearby search GoogleAPI for the user's current location. It is the default app's
     implementation of the `RestaurantPersistence` dependency.

     Inherits from `NSObject` as to being able to adopt the `CLLocationManagerDelegate` protocol.
     - Todo: Refactor `CLLocationManager` wrangling into façaded dependency.
     */
    class NearbySearch: NSObject {
        init(dependencies: GlobalDependencies = .default) {
            self.dependencies = dependencies

            super.init()

            locationManager.delegate = self
        }

        // MARK: - Stored Properties

        private let dependencies: NetworkDependency

        let locationManager = CLLocationManager()

        var authRequestContinuation: CheckedContinuation<Void, Never>?

        var lastBestLocation: CLLocation?

        var currentLocationContinuation: CheckedContinuation<CLLocation, Error>?
    }
}

// MARK: - Google API Calls

extension GoogleAPI.NearbySearch {
    enum PayloadError: Error {
        case unexpectedStatus(GoogleAPI.PlacesSearchStatus)
    }

    func performNearbyPlaceAPICall(location: CLLocation, searchTerms: String?) async throws -> Data {
        var urlComponents = GoogleAPI.commonNearbySearchComponents

        // Add the remaining query parameters.
        urlComponents.queryItems?.append(contentsOf: [
            .init(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
        ])

        // Add the keyword query item from search items if there's any.
        if let searchTerms = searchTerms.contents {
            urlComponents.queryItems?.append(.init(name: "keyword", value: searchTerms))
        }

        guard let apiCallURL = urlComponents.url else {
            fatalError("How the $%^&* did we manage to screw this one.")
        }

        return try await dependencies.network.dataTask(url: apiCallURL).value
    }

    func decodePlacesNearbySearchResponse(data: Data) throws -> [Restaurant] {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let jsonPayload = try jsonDecoder.decode(GoogleAPI.PlacesNearbySearchResponse.self, from: data)

        guard jsonPayload.status == .ok else {
            throw PayloadError.unexpectedStatus(jsonPayload.status)
        }

        return jsonPayload.results.compactMap { jsonRestaurant in
            Restaurant(googleJSON: jsonRestaurant)
        }
    }
}
