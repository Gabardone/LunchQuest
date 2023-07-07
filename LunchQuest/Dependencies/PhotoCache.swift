//
//  PhotoCache.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 4/30/23.
//

import os
import SwiftCache
import UIKit

typealias PhotoCache = any Cache<UIImage, PhotoCacheID>

extension Logger {
    static let photoCacheLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PhotoCache")
}

enum PhotoCacheError: Error {
    case dataNotConvertibleToImage
}

/**
 ID type for use on `PhotoCache`
 */
struct PhotoCacheID {
    var id: Photo.ID

    enum MaxSize: Hashable {
        case original
        case width(Int)
        case height(Int)
        case size(width: Int, height: Int)

        var fileNameString: String? {
            switch self {
            case .original:
                return nil

            case let .width(width):
                return "w\(width)"

            case let .height(height):
                return "h\(height)"

            case let .size(width: width, height: height):
                return "w\(width)-h\(height)"
            }
        }
    }

    var maxSize: MaxSize
}

extension PhotoCacheID {
    private static let photoReferenceQueryItem = "photo_reference"

    var queryItems: [URLQueryItem] {
        var result = maxSize.queryItems
        result.append(.init(name: Self.photoReferenceQueryItem, value: id.rawValue))
        return result
    }
}

extension PhotoCacheID.MaxSize {
    private static let maxHeightQueryKey = "maxheight"

    private static let maxWidthQueryKey = "maxwidth"

    var queryItems: [URLQueryItem] {
        switch self {
        case .original:
            return []

        case let .height(height):
            return [.init(name: Self.maxHeightQueryKey, value: "\(height)")]

        case let .width(width):
            return [.init(name: Self.maxWidthQueryKey, value: "\(width)")]

        case let .size(width, height):
            return [
                .init(name: Self.maxWidthQueryKey, value: "\(width)"),
                .init(name: Self.maxHeightQueryKey, value: "\(height)")
            ]
        }
    }
}

extension PhotoCacheID.MaxSize: CustomStringConvertible {
    var description: String {
        switch self {
        case .original:
            return "original"

        case let .height(height):
            return "h\(height)"

        case let .width(width):
            return "w\(width)"

        case let .size(width, height):
            return "w\(width)xh\(height)"
        }
    }
}

extension PhotoCacheID: Hashable {}

extension PhotoCacheID: CustomStringConvertible {
    var description: String {
        "\(id)-\(maxSize)"
    }
}

extension Photo {
    /// Per Google's `PlacePhoto` API, images won't be bigger than 1600 on either dimension.
    static let sizeRange = 1 ... 1600

    func cacheID(filling: CGSize) -> PhotoCacheID {
        .init(
            id: id,
            maxSize: {
                let originalAspectRatio = originalSize.aspectRatio
                let fillingAspectRatio = filling.aspectRatio

                guard !originalAspectRatio.isInfinite, !fillingAspectRatio.isInfinite else {
                    // Got a division by zero going on. Let's just log and return the original.
                    Logger.photoCacheLogger.error("Image with infinite aspect ratio. Ignoring and returning original")
                    return .original
                }

                if originalAspectRatio > fillingAspectRatio {
                    // photo is wider than canvas. Ask for height or return original if smaller than filling height.
                    return originalSize.height > filling.height ?
                        .height(Int(filling.height.rounded()).clamped(to: Self.sizeRange)) :
                        .original
                } else {
                    // photo is higher than canvas. Ask for width or return original if smaller than filling width.
                    return originalSize.width > filling.width ?
                        .width(Int(filling.width.rounded()).clamped(to: Self.sizeRange)) :
                        .original
                }
            }()
        )
    }
}

protocol PhotoCacheDependency {
    var photoCache: PhotoCache { get }
}

extension GlobalDependencies: PhotoCacheDependency {
    private static var singleton: PhotoCache = GoogleAPI.buildPhotoCache()

    var photoCache: PhotoCache {
        resolveDependency(forKeyPath: \.photoCache, defaultImplementation: Self.singleton)
    }
}
