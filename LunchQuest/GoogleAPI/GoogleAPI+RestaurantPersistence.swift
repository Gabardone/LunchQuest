//
//  GoogleAPI+RestaurantPersistence.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import CoreLocation
import Foundation
import LocationDependency

extension GoogleAPI.NearbySearch: RestaurantPersistence {
    func fetchNearbyRestaurants(searchTerms: String?) async throws -> RestaurantSearchResults {
        GoogleAPI.logger.info("Fetch nearby restaurants: Starting process")

        try await dependencies.locationManager.verifyUserPermissionToAccessLocation()

        GoogleAPI.logger.info("Fetch nearby restaurants: Obtained permission to access location")

        let currentLocation = try await dependencies.locationManager.obtainCurrentLocation()

        GoogleAPI.logger.info("Fetch nearby restaurants: Obtained current location = \(currentLocation)")

        let apiData = try await performNearbyPlaceAPICall(location: currentLocation, searchTerms: searchTerms)

        GoogleAPI.logger.info("Fetch nearby restaurants: Retrieved API data = \(apiData)")

        let restaurants = try decodePlacesNearbySearchResponse(data: apiData)

        GoogleAPI.logger.info("Fetch nearby restaurants: Decoded \(restaurants.count) restaurants")

        return .init(location: currentLocation, restaurants: restaurants)
    }
}
