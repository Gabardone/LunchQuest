//
//  GoogleAPITests.swift
//  LunchQuestTests
//
//  Created by Óscar Morales Vivó on 5/20/23.
//

import CoreLocation
import FileSystemDependency
@testable import LunchQuest
import NetworkDependency
import XCTest

/**
 Sanity tests for GoogleAPI logic.
 */
final class GoogleAPITests: XCTestCase {
    private static let petersCreek = CLLocation(latitude: 37.27661, longitude: -122.19913) // You should go there.

    func testPerformNearbyPlaceAPICall() async throws {
        let searchTerms = "I Like Potatoes"
        let expectedData = "I like chocolate milk".data(using: .utf8)!
        let networkExpectation = expectation(description: "Network called")
        let mockNetwork = MockNetwork { url in
            networkExpectation.fulfill()
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                XCTFail("Received URL cannot be decomposed into components")
                return expectedData
            }

            // Now we check that the URL is what we expect.
            let expectedComponents = GoogleAPI.commonNearbySearchComponents
            XCTAssertEqual(components.scheme, expectedComponents.scheme)
            XCTAssertEqual(components.host, expectedComponents.host)
            XCTAssertEqual(components.path, expectedComponents.path)

            let expectedQueryItems = Set(expectedComponents.queryItems!)
            let receivedQueryItems = Set(components.queryItems!)
            XCTAssertTrue(receivedQueryItems.isSuperset(of: expectedQueryItems))

            // Check the location.
            if let locationItem = receivedQueryItems.first(where: { queryItem in
                queryItem.name == "location"
            }),
                let latLong = locationItem.value?.components(separatedBy: ","),
                let latitude = Double(latLong[0]),
                let longitude = Double(latLong[1]) {
                XCTAssertEqual(latitude, Self.petersCreek.coordinate.latitude, accuracy: 0.00001)
                XCTAssertEqual(longitude, Self.petersCreek.coordinate.longitude, accuracy: 0.00001)
            } else {
                XCTFail("Couldn't find expected location query item with the right format.")
            }

            // Check the search terms.
            if let keywordItem = receivedQueryItems.first(where: { queryItem in
                queryItem.name == "keyword"
            }) {
                XCTAssertEqual(keywordItem.value, searchTerms)
            } else {
                XCTFail("Couldn't find expected keywords query item.")
            }

            return expectedData
        }

        let anyNetwork: any Network = mockNetwork
        let nearbySearch = GoogleAPI.NearbySearch(
            dependencies: GlobalDependencies.default.with(override: anyNetwork, for: \.network)
        )

        let rawData = try await nearbySearch.performNearbyPlaceAPICall(
            location: Self.petersCreek, searchTerms: searchTerms
        )

        XCTAssertEqual(rawData, expectedData)

        await fulfillment(of: [networkExpectation])
    }

    func testDecodePlacesNearbySearchResponseGoodData() throws {
        guard let jsonURL = Bundle(for: Self.self).url(forResource: "Cupertino", withExtension: "json") else {
            XCTFail("Couldn't load json")
            return
        }

        let jsonData = try Data(contentsOf: jsonURL)

        let nearbySearch = GoogleAPI.NearbySearch()
        let decodedRestaurants = try nearbySearch.decodePlacesNearbySearchResponse(data: jsonData)

        XCTAssertEqual(decodedRestaurants.count, 7)
    }

    func testDecodePlacesNearbySearchResponseEmptyResults() throws {
        guard let jsonURL = Bundle(for: Self.self).url(forResource: "MiddleOfNowhere", withExtension: "json") else {
            XCTFail("Couldn't load json")
            return
        }

        let jsonData = try Data(contentsOf: jsonURL)

        let nearbySearch = GoogleAPI.NearbySearch()
        let decodedRestaurants = try nearbySearch.decodePlacesNearbySearchResponse(data: jsonData)

        XCTAssertEqual(decodedRestaurants.count, 0)
    }

    func testDecodePlacesNearbySearchResponseBadResults() throws {
        guard let jsonURL = Bundle(for: Self.self).url(forResource: "BadCallSon", withExtension: "json") else {
            XCTFail("Couldn't load json")
            return
        }

        let jsonData = try Data(contentsOf: jsonURL)

        let nearbySearch = GoogleAPI.NearbySearch()
        do {
            let decodedRestaurants = try nearbySearch.decodePlacesNearbySearchResponse(data: jsonData)
            XCTFail("Unexpectedly completed without error. Result = \(decodedRestaurants)")
        } catch let GoogleAPI.NearbySearch.NearbySearchError.unexpectedPayloadStatus(status) {
            XCTAssertEqual(status, .invalidRequest)
        } catch {
            XCTFail("Unexpected error thrown")
        }
    }

    /// Checks the bare minimum data we need to create a display restaurant for the app.
    func testIncompleteJSONRestaurants() {
        let verifyIncompleteJSONPlace = {
            XCTAssertNil(Restaurant(googleJSON: $0))
        }

        let name = "Adega"
        let placeId = "Potato"
        let geometry = GoogleAPI.Geometry(location: .init(lat: 37.0, lng: -110))

        verifyIncompleteJSONPlace(.init())
        verifyIncompleteJSONPlace(.init(name: name))
        verifyIncompleteJSONPlace(.init(placeId: placeId))
        verifyIncompleteJSONPlace(.init(geometry: geometry))
        verifyIncompleteJSONPlace(.init(placeId: placeId, name: name))
        verifyIncompleteJSONPlace(.init(placeId: placeId, geometry: geometry))
        verifyIncompleteJSONPlace(.init(name: name, geometry: geometry))

        XCTAssertNotNil(Restaurant(googleJSON: GoogleAPI.Place(placeId: placeId, name: name, geometry: geometry)))
    }

    private func buildTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(.init(origin: .zero, size: size))
            UIColor.yellow.setStroke()

            let cgContext = context.cgContext
            cgContext.setLineWidth(2.0)

            cgContext.beginPath()
            cgContext.move(to: .zero)
            cgContext.addLine(to: .init(x: size.width, y: size.height))
            cgContext.strokePath()

            cgContext.beginPath()
            cgContext.move(to: .init(x: 0.0, y: size.height))
            cgContext.addLine(to: .init(x: size.width, y: 0.0))
            cgContext.strokePath()
        }
    }

    /// Checks the standard behavior of the built image cache.
    func testImageCache() async throws {
        // We're going to need a dummy image to get the data from and pass around.
        let imageCGSize = CGSize(width: 10.0, height: 10.0)
        let imageSize = PhotoCacheID.MaxSize.size(width: 10, height: 10)
        let image = buildTestImage(size: imageCGSize)

        guard let pngData = image.pngData() else {
            XCTFail("Uh, can't get the image data")
            return
        }

        let mockImageID = PhotoCacheID(id: .init(rawValue: "Potato"), maxSize: imageSize)

        let networkExpectation = expectation(description: "Called `Network.dataFor(url:)`")
        let mockNetwork = MockNetwork { url in
            XCTAssertEqual(url, mockImageID.placePhotoURL)
            networkExpectation.fulfill()
            return pngData
        }

        let writeDataExpectation = expectation(description: "Called `FileSystem.write(data:fileURL:doNotOverwrite:`")
        let mockFileSystem = ComposableFileSystem(
            dataForOverride: { _ in
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
            },
            writeDataOverride: { data, fileURL, doNotOverwrite in
                XCTAssertEqual(data, pngData)
                XCTAssertEqual(fileURL, GoogleAPI.photoCacheLocalFileDirectory.appending(component: "\(mockImageID)"))
                XCTAssertFalse(doNotOverwrite)
                writeDataExpectation.fulfill()
            },
            removeFileAtOverride: { _ in XCTFail("remove file") },
            makeDirectoryAtOverride: { _ in XCTFail("make directory") }
        )

        var mockingDependencies = GlobalDependencies.default
        mockingDependencies.override(keyPath: \.network, with: mockNetwork)
        mockingDependencies.override(keyPath: \.fileSystem, with: mockFileSystem)

        let imageCache = GoogleAPI.buildPhotoCache(dependencies: mockingDependencies)

        let cachedImage = try await imageCache.cachedValueWith(identifier: mockImageID)

        await fulfillment(of: [networkExpectation, writeDataExpectation])

        // The actual image size will depend on scaling factor, but we can test for it existing and being square.
        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(cachedImage?.size.width, cachedImage?.size.height)
        XCTAssertNotEqual(cachedImage?.size.width, 0)
    }
}
