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
    static func buildPhotoCache() -> PhotoCache {
        let networkDataSource = NetworkReadOnlyDataStorage()
        let networkSource = BackstopStorageCache(
            storage: networkDataSource) { (cacheID: PhotoCacheID) in
                var urlComponents = GoogleAPI.commonPlacePhotoComponents
                urlComponents.queryItems?.append(contentsOf: [
                    .init(name: "photo_reference", value: cacheID.id.rawValue)
                ])

                urlComponents.queryItems?.append(contentsOf: cacheID.maxSize.queryItems)

                return urlComponents.url!
            }

        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "PlacePhotoCache", directoryHint: .isDirectory
        )
        let localFileDataSource: LocalFileDataStorage
        do {
            try localFileDataSource = .init(rootDirectory: directoryURL)
        } catch {
            try! localFileDataSource = .init() // swiftlint:disable:this force_try
        }
        let localCache = TemporaryStorageCache(
            next: networkSource,
            storage: localFileDataSource
        ) { (cacheID: PhotoCacheID) in
            // Using the identifier and size as the file name.
            var result = "\(cacheID.id.rawValue)"
            if let sizingString = cacheID.maxSize.fileNameString {
                result += "-" + sizingString
            }
            return result
        }

        return TemporaryStorageCache(next: localCache, storage: WeakObjectStorage()) { (data: Data) in
            if let image = UIImage(data: data) {
                return image
            }

            throw PhotoCacheError.dataNotConvertibleToImage
        }
    }
}
