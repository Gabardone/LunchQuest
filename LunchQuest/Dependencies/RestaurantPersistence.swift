//
//  RestaurantPersistence.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/15/23.
//

import Foundation
import GlobalDependencies

/**
 Declares the behaviors that we require to obtain information about nearby restaurants.
 */
protocol RestaurantPersistence {
    /**
     Returns the list of nearby restaurants resulting of searching nearby with the given optional keywords.
     - Parameter searchTerms: The keywords to add to the search. If `nil` it just does a generic nearby search for
     restaurants.
     - Returns: The result of the search. Or throws if there is an issue.
     */
    func fetchNearbyRestaurants(searchTerms: String?) async throws -> RestaurantSearchResults
}

/// Dependency protocol for restaurant persistence.
protocol RestaurantPersistenceDependency: Dependencies {
    var restaurantPersistence: any RestaurantPersistence { get }
}

/// Dependency protocol implementation for GlobalDependencies
extension GlobalDependencies: RestaurantPersistenceDependency {
    private static let `default` = GoogleAPI.NearbySearch()

    var restaurantPersistence: any RestaurantPersistence {
        resolveDependency(forKeyPath: \.restaurantPersistence, defaultImplementation: Self.default)
    }
}
