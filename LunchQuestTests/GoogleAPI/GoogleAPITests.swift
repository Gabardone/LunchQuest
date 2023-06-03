//
//  GoogleAPITests.swift
//  LunchQuestTests
//
//  Created by Óscar Morales Vivó on 5/20/23.
//

import CoreLocation
@testable import LunchQuest
import MiniDePin
import NetworkDependency
import XCTest

/**
 Sanity tests for GoogleAPI logic.
 */
final class GoogleAPITests: XCTestCase {
    private static let petersCreek = CLLocation(latitude: 37.27661, longitude: -122.19913) // You should go there.

    func testPerformNearbyPlaceAPICall() async throws {
        let searchTerms = "I Like Potatoes"
        let expectedData = "I like chocolate milk".data(using: .utf8)!
        let networkExpectation = expectation(description: "Network called")
        let mockNetwork = MockNetwork { url in
            networkExpectation.fulfill()
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                XCTFail("Received URL cannot be decomposed into components")
                return Task { expectedData }
            }

            // Now we check that the URL is what we expect.
            let expectedComponents = GoogleAPI.commonNearbySearchComponents
            XCTAssertEqual(components.scheme, expectedComponents.scheme)
            XCTAssertEqual(components.host, expectedComponents.host)
            XCTAssertEqual(components.path, expectedComponents.path)

            let expectedQueryItems = Set(expectedComponents.queryItems!)
            let receivedQueryItems = Set(components.queryItems!)
            XCTAssertTrue(receivedQueryItems.isSuperset(of: expectedQueryItems))

            // Check the location.
            if let locationItem = receivedQueryItems.first(where: { queryItem in
                queryItem.name == "location"
            }),
                let latLong = locationItem.value?.components(separatedBy: ","),
                let latitude = Double(latLong[0]),
                let longitude = Double(latLong[1]) {
                XCTAssertEqual(latitude, Self.petersCreek.coordinate.latitude, accuracy: 0.00001)
                XCTAssertEqual(longitude, Self.petersCreek.coordinate.longitude, accuracy: 0.00001)
            } else {
                XCTFail("Couldn't find expected location query item with the right format.")
            }

            // Check the search terms.
            if let keywordItem = receivedQueryItems.first(where: { queryItem in
                queryItem.name == "keyword"
            }) {
                XCTAssertEqual(keywordItem.value, searchTerms)
            } else {
                XCTFail("Couldn't find expected keywords query item.")
            }

            return Task { expectedData }
        }

        let anyNetwork: any Network = mockNetwork
        let nearbySearch = GoogleAPI.NearbySearch(
            dependencies: GlobalDependencies.default.with(override: anyNetwork, for: \.network)
        )

        let rawData = try await nearbySearch.performNearbyPlaceAPICall(
            location: Self.petersCreek, searchTerms: searchTerms
        )

        XCTAssertEqual(rawData, expectedData)

        await fulfillment(of: [networkExpectation])
    }
}
