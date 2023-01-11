//
//  URLSessionNetwork.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 3/29/23.
//

import Foundation

struct URLSessionNetwork {}

extension URLSessionNetwork: Network {
    func dataTask(url: URL) -> Task<Data, Error> {
        Task {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    }
}
