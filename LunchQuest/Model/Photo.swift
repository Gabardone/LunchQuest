//
//  Photo.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 4/29/23.
//

import Foundation
import StronglyTypedID

struct Photo: Identifiable {
    struct ID: StronglyTypedID {
        var rawValue: String
    }

    /**
     We use Google's `photoReference` identifier as the photo ID.
     */
    var id: ID

    /**
     At some point these should be displayed.
     */
    var htmlAttributions: [String]

    var originalSize: CGSize
}

extension Photo: Equatable {
    static func == (_ lhs: Photo, _ rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}

extension Photo: Hashable {
    func hash(into: inout Hasher) {
        id.hash(into: &into)
    }
}
