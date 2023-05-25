//
//  Network.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/16/23.
//

import Foundation
import MiniDePin

protocol Network {
    func dataTask(url: URL) -> Task<Data, Error>
}

protocol NetworkDependency: Dependencies {
    var network: any Network { get }
}

extension GlobalDependencies: NetworkDependency {
    private static let defaultNetwork: any Network = URLSessionNetwork()

    var network: any Network {
        resolveDependency(forKeyPath: \.network, defaultImplementation: Self.defaultNetwork)
    }
}
