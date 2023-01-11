//
//  GoogleAPI+PlacePhoto.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 4/29/23.
//

import Foundation

extension GoogleAPI {
    struct PlacePhoto: Decodable {
        var photoReference: String

        var htmlAttributions: [String]

        var height: CGFloat

        var width: CGFloat
    }
}

extension Photo {
    init(googleJSON: GoogleAPI.PlacePhoto) {
        self.id = .init(rawValue: googleJSON.photoReference)
        self.htmlAttributions = googleJSON.htmlAttributions
        self.originalSize = .init(width: googleJSON.width, height: googleJSON.height)
    }
}
