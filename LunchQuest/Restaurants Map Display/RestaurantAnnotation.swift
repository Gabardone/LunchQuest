//
//  RestaurantAnnotation.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import Foundation
import MapKit

class RestaurantAnnotation: NSObject {
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }

    var restaurant: Restaurant
}

extension RestaurantAnnotation: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: restaurant.latitude, longitude: restaurant.longitude)
    }

    var title: String? {
        restaurant.name
    }
}
