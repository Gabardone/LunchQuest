//
//  GoogleAPI+NearbySearchPayload.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/16/23.
//

import Foundation

/**
 Bridge value types to read JSON data form the Google places API.

 Making `Restaurant` implement `Decodable` locks it to a specific encoded representation and because we don't want to be
 using the exact same identifiers or types as the JSON data we get from the network we also have to basically implement
 the whole of `Decodable` by hand.

 Using a helper type means we can just have it read JSON straight and then leave the translation complexity to a
 separate initialization method.
 */
extension GoogleAPI {
    /**
     The various status that the API may return, declared as `PlacesSearchStatus` in the Google API documentation,
     which can be found
     [here](https://developers.google.com/maps/documentation/places/web-service/search-nearby#PlacesSearchStatus).
     */
    enum PlacesSearchStatus: String, Equatable, Decodable {
        /// The API request was successful.
        case ok = "OK"

        /// The search was successful but returned no results. This may occur if the search was passed a latlng in a
        /// remote location.
        case empty = "ZERO_RESULTS"

        /// The API request was malformed, generally due to missing required query parameter (location or radius).
        case invalidRequest = "INVALID_REQUEST"

        /// Indicating any of the following:
        /// - You have exceeded the QPS limits.
        /// - Billing has not been enabled on your account.
        /// - The monthly $200 credit, or a self-imposed usage cap, has been exceeded.
        /// - The provided method of payment is no longer valid (for example, a credit card has expired).
        case overQueryLimit = "OVER_QUERY_LIMIT"

        /// The request was denied, usually due to one of the following reasons:
        /// - The request is missing an API key.
        /// - The key parameter is invalid.
        case requestDenied = "REQUEST_DENIED"

        /// Something bad happened.
        case unknownError = "UNKNOWN_ERROR"
    }

    /**
     Simple type used by the Google API to store map coordinates. Google API documentation for the type can be found
     [here](https://developers.google.com/maps/documentation/places/web-service/search-nearby#LatLngLiteral)
     */
    struct LatLngLiteral: Decodable {
        var lat: Double

        var lng: Double
    }

    /**
     Subset of `Geometry`. Google API documentation for the type can be found
     [here](https://developers.google.com/maps/documentation/places/web-service/search-nearby#Geometry)
     */
    struct Geometry: Decodable {
        var location: LatLngLiteral
    }

    /**
     All the place data returned by the API is, per the documentation, optional. This makes it mostly unusable in
     the context of the app, so in the case that anything is missing critical data it will be filtered out as it gets
     translated to app model types.

     JSON decoding requires `keyDecodingStrategy` to be `convertFromSnakeCase`

     Google API documentation for the type can be found
     [here](https://developers.google.com/maps/documentation/places/web-service/search-nearby#Place)
     */
    struct Place: Decodable {
        var placeId: String?

        var name: String?

        var rating: Double?

        var icon: URL?

        var photos: [PlacePhoto]?

        var geometry: Geometry?

        var userRatingsTotal: Int

        var vicinity: String?

        var website: String?

        var priceLevel: Int?
    }

    /**
     Subset of `PlacesNearbySearchResponse`. Google API documentation for the type can be found
     [here](https://developers.google.com/maps/documentation/places/web-service/search-nearby#PlacesNearbySearchResponse)
     */
    struct PlacesNearbySearchResponse: Decodable {
        var results: [Place]

        var status: PlacesSearchStatus
    }
}

extension Restaurant {
    /**
     Translation from Google API `Place` type to `Restaurant`.

     It is failable as we will ignore places that don't have enough information to be useful for our purposes.
     - Parameter googleJSON: The Google API JSON parsed type.
     */
    init?(googleJSON: GoogleAPI.Place) {
        // Check first the ones we don't want to be without.
        guard let id = googleJSON.placeId,
              let name = googleJSON.name,
              let location = googleJSON.geometry?.location else {
            // Can't build a thing without an ID, and we don't want to eat at The Restaurant With No Name, nor a
            // restaurant that cannot be found in this dimension.
            return nil
        }

        self.id = .init(rawValue: id)

        self.name = name

        self.priceLevel = googleJSON.priceLevel.flatMap { PriceLevel(rawValue: $0) }

        self.rating = googleJSON.rating

        self.reviewCount = googleJSON.userRatingsTotal

        self.address = googleJSON.vicinity

        self.photo = googleJSON.photos?.first.map { Photo(googleJSON: $0) }

        self.latitude = location.lat

        self.longitude = location.lng

        self.website = googleJSON.website.flatMap { URL(string: $0) }
    }
}
