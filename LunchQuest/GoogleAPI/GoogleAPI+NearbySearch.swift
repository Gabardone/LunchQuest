//
//  GoogleAPI+NearbySearch.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/15/23.
//

import CoreLocation
import Foundation
import LocationDependency
import NetworkDependency

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
     */
    class NearbySearch {
        init(dependencies: GlobalDependencies = .default) {
            self.dependencies = dependencies
        }

        // MARK: - Stored Properties

        let dependencies: any NetworkDependency & LocationManagerDependency
    }
}

// MARK: - Google API Calls

extension GoogleAPI.NearbySearch {
    enum NearbySearchError: Error {
        case unexpectedPayloadStatus(GoogleAPI.PlacesSearchStatus)
        case invalidURLComponents(URLComponents)
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
            throw NearbySearchError.invalidURLComponents(urlComponents)
        }

        return try await dependencies.network.dataFor(url: apiCallURL)
    }

    func decodePlacesNearbySearchResponse(data: Data) throws -> [Restaurant] {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let jsonPayload = try jsonDecoder.decode(GoogleAPI.PlacesNearbySearchResponse.self, from: data)

        guard jsonPayload.status == .ok || jsonPayload.status == .empty else {
            throw NearbySearchError.unexpectedPayloadStatus(jsonPayload.status)
        }

        return jsonPayload.results.compactMap { jsonRestaurant in
            Restaurant(googleJSON: jsonRestaurant)
        }
    }
}
