//
//  NearbySearchControllerTests.swift
//  LunchQuestTests
//
//  Created by Óscar Morales Vivó on 7/2/23.
//

import CoreLocation
@testable import LunchQuest
import SwiftUX
import XCTest

final class NearbySearchControllerTests: XCTestCase {
    struct MockError: Error {}

    private class MockRestaurantPersistence: RestaurantPersistence {
        var fetchNearbyRestaurantsOverride: ((String?) async throws -> LunchQuest.RestaurantSearchResults)?
        func fetchNearbyRestaurants(searchTerms: String?) async throws -> LunchQuest.RestaurantSearchResults {
            if let fetchNearbyRestaurantsOverride {
                return try await fetchNearbyRestaurantsOverride(searchTerms)
            } else {
                throw MockError()
            }
        }
    }

    private static let petersCreek = CLLocation(latitude: 37.27661, longitude: -122.19913) // You should go there.

    @MainActor
    func testHappySearch() async {
        let mockPersistence = MockRestaurantPersistence()
        let model = NearbySearchController.ModelProperty.root(initialValue: .uninitialized)
        let searchController = NearbySearchController(id: UUID(), model: model, persistence: mockPersistence)

        let mockSearchTerms = "Potato"
        let mockResults = RestaurantSearchResults(location: Self.petersCreek, restaurants: [])
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

            case let .success(data: searchResults):
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
            throw MockError()
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

            case let .error(error: error):
                errorExpectation.fulfill()
                XCTAssertTrue(hasStartedLoading)
                XCTAssertTrue(error is MockError)

            default:
                XCTFail("Unexpectedly updated controller's model to \(loadState)")
            }
        }

        searchController.fetchNearbyRestaurants(searchTerms: mockSearchTerms)

        await fulfillment(of: [fetchExpectation, loadingExpectation, errorExpectation], timeout: 100.0)

        subscription.cancel()
    }

    func testSearchResultsModel() {
        let loadingStateModel = WritableProperty.root(initialValue: LoadState<RestaurantSearchResults>.uninitialized)
        let initialModel = RestaurantSearchResults(location: Self.petersCreek, restaurants: [])
        let searchResultsModel = loadingStateModel.searchResultsModel(initialValue: initialModel)

        XCTAssertEqual(searchResultsModel.value, initialModel)

        let laterModel = RestaurantSearchResults(location: Self.petersCreek, restaurants: [.init(
            id: .init(rawValue: "Pizza!"),
            latitude: Self.petersCreek.coordinate.latitude,
            longitude: Self.petersCreek.coordinate.longitude,
            name: "Redwoods Pizza"
        )])

        let updateExpectation = expectation(description: "Got a search results update")
        let subscription = searchResultsModel.updates.sink { searchResults in
            updateExpectation.fulfill()
            XCTAssertEqual(searchResults, laterModel)
        }

        // We run some other flows to enusre that we _only_ get updates when the results themselves are updated.
        loadingStateModel.value = .loading(task: Task {}, searchTerms: "Pizza!")
        loadingStateModel.value = .error(error: MockError())

        XCTAssertEqual(searchResultsModel.value, initialModel)

        loadingStateModel.value = .loading(task: Task {}, searchTerms: "Redwoods!")
        loadingStateModel.value = .success(data: laterModel)
        loadingStateModel.value = .done

        waitForExpectations(timeout: 1.0)

        subscription.cancel()
    }
}
