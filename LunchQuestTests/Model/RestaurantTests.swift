//
//  RestaurantTests.swift
//  LunchQuestTests
//
//  Created by Óscar Morales Vivó on 5/20/23.
//

@testable import LunchQuest
import XCTest

/**
 `Restaurant` is just a bucket of data lightly processed from the network so there's not a whole lot to unit test, but
 the extensions to build display strings can use it.

 These tests currently only are guaranteed to work on English localization.
 */
final class RestaurantTests: XCTestCase {
    func testUnrated() {
        let restaurant = Restaurant(id: .init(rawValue: "Potato"), latitude: 0.0, longitude: 0.0, name: "Potato!")

        XCTAssertEqual(restaurant.ratingString, "Unrated")
    }

    func testOnlyStarRating() {
        let rating = 4.5
        let restaurant = Restaurant(
            id: .init(rawValue: "Potato"),
            latitude: 0.0,
            longitude: 0.0,
            name: "Potato!",
            rating: rating
        )

        XCTAssertEqual(restaurant.ratingString, "⭐️ \(rating)")
    }

    func testOnlyReviewCount() {
        let reviewCount = 777
        let restaurant = Restaurant(
            id: .init(rawValue: "Potato"),
            latitude: 0.0,
            longitude: 0.0,
            name: "Potato!",
            reviewCount: reviewCount
        )

        XCTAssertEqual(restaurant.ratingString, "\(reviewCount) reviews")
    }

    func testFullRating() {
        let rating = 4.5
        let reviewCount = 777
        let restaurant = Restaurant(
            id: .init(rawValue: "Potato"),
            latitude: 0.0,
            longitude: 0.0,
            name: "Potato!",
            rating: rating,
            reviewCount: reviewCount
        )

        XCTAssertEqual(restaurant.ratingString, "⭐️ \(rating) • \(reviewCount) reviews")
    }

    func testPriceLevel() {
        XCTAssertEqual(Restaurant.PriceLevel.free.priceString, "Price level: Gratis!")
        XCTAssertEqual(Restaurant.PriceLevel.inexpensive.priceString, "Price level: 💵")
        XCTAssertEqual(Restaurant.PriceLevel.moderate.priceString, "Price level: 💵💵")
        XCTAssertEqual(Restaurant.PriceLevel.expensive.priceString, "Price level: 💵💵💵")
        XCTAssertEqual(Restaurant.PriceLevel.veryExpensive.priceString, "Price level: 💵💵💵💵")
    }
}
