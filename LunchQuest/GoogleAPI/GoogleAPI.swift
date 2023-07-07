//
//  GoogleAPI.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/5/23.
//

import Foundation
import os

/**
 Namespace `enum` for the actual Google API client implementation.
 */
enum GoogleAPI {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "GoogleAPI")

    static let ErrorDomain = "GoogleAPIErrorDomain"

    /// Import this from some vault in a real-world use case.
    private static let apiKey = "<<BRING YOUR OWN API KEY>>"

    static let commonURLComponents: URLComponents = {
        var commonURLComponents = URLComponents()
        commonURLComponents.scheme = "https"
        commonURLComponents.host = "maps.googleapis.com"
        commonURLComponents.path = "/maps/api/place"
        commonURLComponents.queryItems = [
            .init(name: "key", value: apiKey)
        ]
        return commonURLComponents
    }()
}
