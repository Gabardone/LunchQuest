//
//  NearbyLoaderController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/15/23.
//

import Combine
import Foundation
import SwiftUX

class NearbySearchController: WritableController<UUID, LoadState<RestaurantSearchResults>, RestaurantPersistence> {}

extension NearbySearchController {
    struct LoadStateError: Error {
        var fromState: Model

        var toState: Model

        var localizedDescription: String {
            "Load state unexpectedly going from \(fromState) to \(toState)"
        }
    }

    func fetchNearbyRestaurants(searchTerms: String?) {
        apply { loadState in
            if case let .loading(_, priorTerms) = loadState, priorTerms == searchTerms {
                // We're not going to re-start a search for the same terms until it errors out or finishes.
                return loadState
            }

            // For any other state, start loading.
            return .loading(
                task: Task { [weak self] in
                    guard let self else { return }
                    do {
                        let searchResults = try await self.persistence.fetchNearbyRestaurants(searchTerms: searchTerms)
                        self.success(searchResults: searchResults)
                    } catch {
                        self.fail(error: error)
                    }
                },
                searchTerms: searchTerms
            )
        }
    }

    private func fail(error: Error) {
        apply { _ in
            .error(error: error)
        }
    }

    private func success(searchResults: RestaurantSearchResults) {
        // We're not expecting any uncaught errors here, the sync parts are guaranteed to work.
        apply { loadState in
            switch loadState {
            case .loading:
                return .success(data: searchResults)

            default:
                // Definitely screwed up the state machine.
                return .error(error: LoadStateError(fromState: loadState, toState: .success(data: searchResults)))
            }
        }

        // After success, done.
        apply { loadState in
            switch loadState {
            case .success:
                return .done

            default:
                // Definitely screwed up the state machine.
                return .error(error: LoadStateError(fromState: loadState, toState: .done))
            }
        }
    }
}

extension WritableProperty where Value == LoadState<RestaurantSearchResults> {
    func searchResultsModel(initialValue: RestaurantSearchResults) -> ReadOnlyProperty<RestaurantSearchResults> {
        var lastValue = initialValue
        let passthrough = PassthroughSubject<RestaurantSearchResults, Never>()
        var subscription: (any Cancellable)?

        // We're going to need to keep `lastValue` up to date and also ensure that the passthrough subject sends after
        // it changes.
        subscription = updates.sink { value in
            if case let .success(searchResults) = value {
                lastValue = searchResults
                passthrough.send(searchResults)
            }
        }

        // We capture `subscription` in the getter block so it is released with the block (whenever the model is no
        // longer in use).
        return .init(updates: passthrough) { [subscription] in
            _ = subscription
            return lastValue
        }
    }
}
