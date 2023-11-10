//
//  GoogleAPI+PhotoCache.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/8/23.
//

import SwiftCache
import UIKit

extension GoogleAPI {
    fileprivate static let commonPlacePhotoComponents: URLComponents = {
        var commonPlacePhotoComponents = commonURLComponents
        commonPlacePhotoComponents.path.append("/photo")
        return commonPlacePhotoComponents
    }()

    /**
     Builds a cache that will get photos from Google's `PlacePhoto` API and store them locally/in memory as needed.
     */
    static func buildPhotoCache(dependencies: GlobalDependencies = .default) -> some PhotoCache {
        let networkDataSource = NetworkDataSource(dependencies: dependencies)
        let networkSource = BackstopStorageCache(
            storage: networkDataSource,
            idConverter: \PhotoCacheID.placePhotoURL
        )

        let localFileDataSource = LocalFileDataStorage(dependencies: dependencies)
        let localCache = TemporaryStorageCache(
            next: networkSource,
            storage: localFileDataSource,
            rootDirectory: photoCacheLocalFileDirectory
        )

        return TemporaryStorageCache(next: localCache, storage: WeakObjectStorage()) { (data: Data) in
            if let image = UIImage(data: data) {
                return image
            }

            throw PhotoCacheError.dataNotConvertibleToImage
        }
    }

    static var photoCacheLocalFileDirectory: URL {
        FileManager.default.temporaryDirectory.appending(
            component: (Bundle.main.bundleIdentifier ?? "") + "PlacePhoto",
            directoryHint: .isDirectory
        )
    }
}

extension TemporaryStorageCache: PhotoCache where CacheID == PhotoCacheID, Cached == UIImage {}

extension PhotoCacheID {
    var placePhotoURL: URL {
        var urlComponents = GoogleAPI.commonPlacePhotoComponents
        urlComponents.queryItems?.append(contentsOf: [
            .init(name: "photo_reference", value: id.rawValue)
        ])

        urlComponents.queryItems?.append(contentsOf: maxSize.queryItems)

        return urlComponents.url!
    }
}
