//
//  NearbySearchControllerTests.swift
//  LunchQuestTests
//
//  Created by Óscar Morales Vivó on 7/2/23.
//

import CoreLocation
@testable import LunchQuest
import XCTest

final class NearbySearchControllerTests: XCTestCase {
    class MockRestaurantPersistence: RestaurantPersistence {
        struct MockError: Error {}

        var fetchNearbyRestaurantsOverride: ((String?) async throws -> LunchQuest.RestaurantSearchResults)?
        func fetchNearbyRestaurants(searchTerms: String?) async throws -> LunchQuest.RestaurantSearchResults {
            if let fetchNearbyRestaurantsOverride {
                return try await fetchNearbyRestaurantsOverride(searchTerms)
            } else {
                throw MockError()
            }
        }
    }

    @MainActor
    func testHappySearch() async {
        let mockPersistence = MockRestaurantPersistence()
        let model = NearbySearchController.ModelProperty.root(initialValue: .uninitialized)
        let searchController = NearbySearchController(id: UUID(), model: model, persistence: mockPersistence)

        let mockSearchTerms = "Potato"
        let petersCreek = CLLocation(latitude: 37.27661, longitude: -122.19913) // You should go there.
        let mockResults = RestaurantSearchResults(location: petersCreek, restaurants: [])
        let fetchExpectation = expectation(description: "Called fetchNearbyRestaurants")
        mockPersistence.fetchNearbyRestaurantsOverride = { searchTerms in
            fetchExpectation.fulfill()
            XCTAssertEqual(searchTerms, mockSearchTerms)
            return mockResults
        }

        let loadingExpectation = expectation(description: "Controller's model updated to loading")
        let resultsExpectation = expectation(description: "Controller's model updated with results")
        let doneExpectation = expectation(description: "Controller is done fetching.")
        var hasStartedLoading = false
        var hasResults = false
        let subscription = searchController.model.updates.sink { loadState in
            switch loadState {
            case .loading(task: _, searchTerms: let searchTerms):
                loadingExpectation.fulfill()
                XCTAssertEqual(searchTerms, mockSearchTerms)
                hasStartedLoading = true

            case .success(data: let searchResults):
                XCTAssertTrue(hasStartedLoading)
                resultsExpectation.fulfill()
                XCTAssertEqual(searchResults, mockResults)
                hasResults = true

            case .done:
                XCTAssertTrue(hasResults)
                doneExpectation.fulfill()

            default:
                XCTFail("Unexpectedly updated controller's model to \(loadState)")
            }
        }

        searchController.fetchNearbyRestaurants(searchTerms: mockSearchTerms)

        await fulfillment(of: [fetchExpectation, loadingExpectation, resultsExpectation, doneExpectation], timeout: 100.0)

        subscription.cancel()
    }

    @MainActor
    func testUnhappySearch() async {
        let mockPersistence = MockRestaurantPersistence()
        let model = NearbySearchController.ModelProperty.root(initialValue: .uninitialized)
        let searchController = NearbySearchController(id: UUID(), model: model, persistence: mockPersistence)

        let mockSearchTerms = "Potato"
        let fetchExpectation = expectation(description: "Called fetchNearbyRestaurants")
        mockPersistence.fetchNearbyRestaurantsOverride = { searchTerms in
            fetchExpectation.fulfill()
            XCTAssertEqual(searchTerms, mockSearchTerms)
            throw MockRestaurantPersistence.MockError()
        }

        let loadingExpectation = expectation(description: "Controller's model updated to loading")
        let errorExpectation = expectation(description: "Controller's model updated with error")
        var hasStartedLoading = false
        let subscription = searchController.model.updates.sink { loadState in
            switch loadState {
            case .loading(task: _, searchTerms: let searchTerms):
                loadingExpectation.fulfill()
                XCTAssertEqual(searchTerms, mockSearchTerms)
                hasStartedLoading = true

            case .error(error: let error):
                errorExpectation.fulfill()
                XCTAssertTrue(hasStartedLoading)
                XCTAssertTrue(error is MockRestaurantPersistence.MockError)

            default:
                XCTFail("Unexpectedly updated controller's model to \(loadState)")
            }
        }

        searchController.fetchNearbyRestaurants(searchTerms: mockSearchTerms)

        await fulfillment(of: [fetchExpectation, loadingExpectation, errorExpectation], timeout: 100.0)

        subscription.cancel()
    }
}
