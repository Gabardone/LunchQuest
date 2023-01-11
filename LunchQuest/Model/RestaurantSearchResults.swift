//
//  RestaurantSearchResults.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/7/23.
//

import CoreLocation
import Foundation

/**
 A value type packaging the results of a nearby restaurant search.
 */
struct RestaurantSearchResults: Equatable {
    var location: CLLocation

    var restaurants: [Restaurant]
}
