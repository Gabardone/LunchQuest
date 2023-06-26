//
//  GoogleAPI+PhotoCache.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import SwiftCache
import UIKit

extension GoogleAPI {
    private static let commonPlacePhotoComponents: URLComponents = {
        var commonPlacePhotoComponents = commonURLComponents
        commonPlacePhotoComponents.path.append("/photo")
        return commonPlacePhotoComponents
    }()

    /**
     Builds a cache that will get photos from Google's `PlacePhoto` API and store them locally/in memory as needed.
     */
    static func buildPhotoCache(dependencies: GlobalDependencies = .default) -> PhotoCache {
        let networkDataSource = NetworkDataSource(dependencies: dependencies)
        let networkSource = BackstopStorageCache(
            storage: networkDataSource) { (cacheID: PhotoCacheID) in
                var urlComponents = GoogleAPI.commonPlacePhotoComponents
                urlComponents.queryItems?.append(contentsOf: [
                    .init(name: "photo_reference", value: cacheID.id.rawValue)
                ])

                urlComponents.queryItems?.append(contentsOf: cacheID.maxSize.queryItems)

                return urlComponents.url!
            }

        // Build a temp directory and make sure it exists... Temp folder only use of FileManager is testable.
        let directoryURL: URL = FileManager.default.temporaryDirectory.appending(
            component: (Bundle.main.bundleIdentifier ?? "") + "PlacePhoto",
            directoryHint: .isDirectory
        )

        let localFileDataSource = LocalFileDataStorage(dependencies: dependencies)
        let localCache = TemporaryStorageCache(
            next: networkSource,
            storage: localFileDataSource,
            rootDirectory: directoryURL
        )

        return TemporaryStorageCache(next: localCache, storage: WeakObjectStorage()) { (data: Data) in
            if let image = UIImage(data: data) {
                return image
            }

            throw PhotoCacheError.dataNotConvertibleToImage
        }
    }
}
