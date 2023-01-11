//
//  LoadState.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/12/23.
//

import Combine
import Foundation

/**
 A single-load data loader, such as one used to initialize UI from an async data source with a long latency like a
 networked backend, basically manages a state machine. These are the states.
 */
enum LoadState<T> {
    /// The loader has just been created and has not yet started loading.
    case uninitialized

    /// The loader is currently performing a load. The associated values are the task doing the loading and the search
    /// terms being searched.
    case loading(task: Task<Void, Error>, searchTerms: String?)

    /// The last loading operation ended up with an error, associated to this value.
    case error(error: Error)

    /// The last loading operation ended up successfully, the loaded data is associated to this value.
    case success(data: T)

    /// After a successful load, the state is set to `.done` as to avoid holding onto the returned data
    /// unnecessarily.
    case done
}

extension LoadState: Equatable where T: Equatable {
    /**
     `Error`, as a protocol existential, cannot comply with `Equatable`, but we can get close enough to make it work
     for our needs.
     */
    static func == (lhs: LoadState<T>, rhs: LoadState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized), (.loading, .loading), (.done, .done):
            return true

        case let (.error(lhsError), .error(rhsError)):
            // This is not 100% guaranteed to be correct but should make no difference for our needs.
            return
                type(of: lhsError) == type(of: rhsError) &&
                lhsError.localizedDescription == rhsError.localizedDescription

        case let (.success(lhsData), .success(rhsData)):
            return lhsData == rhsData

        default:
            return false
        }
    }
}
