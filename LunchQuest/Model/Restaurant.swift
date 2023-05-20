//
//  Restaurant.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/15/23.
//

import Foundation
import Iutilitis
import StronglyTypedID

/**
 Simple value type that models a restaurant's data.
 */
struct Restaurant: Hashable, Identifiable {
    struct ID: StronglyTypedID {
        var rawValue: String
    }

    enum PriceLevel: Int {
        case free = 0
        case inexpensive = 1
        case moderate = 2
        case expensive = 3
        case veryExpensive = 4
    }

    var id: ID

    var latitude: Double

    var longitude: Double

    var photo: Photo?

    var name: String

    var priceLevel: PriceLevel?

    var rating: Double?

    var reviewCount: Int?

    var address: String?

    var website: URL?
}

extension Restaurant {
    var ratingString: String {
        // Some work building up the rating line.
        let ratingString = rating.map { ratingString in
            NSLocalizedString(
                "RESTAURANT_RATING_DISPLAY",
                value: "⭐️ \(ratingString)",
                comment: "User-visible rating string."
            )
        }

        let reviewCountString = reviewCount.map { reviewCount in
            NSLocalizedString(
                "RESTAURANT_REVIEW_COUNT_DISPLAY",
                value: "\(reviewCount) reviews",
                comment: "User-visible review count string"
            )
        }

        switch (ratingString, reviewCountString) {
        case (.none, .none):
            return NSLocalizedString(
                "RESTAURANT_REVIEW_UNRATED",
                value: "Unrated",
                comment: "User visible string for a restaurant with no rating set at all"
            )

        case let (.some(ratingString), .none):
            return ratingString

        case let (.none, .some(reviewCountString)):
            return reviewCountString

        case let (.some(ratingString), .some(reviewCountString)):
            return String.localizedStringWithFormat("%@ • %@", ratingString, reviewCountString)
        }
    }
}

extension Restaurant.PriceLevel {
    var priceString: String {
        let localizedFormat = NSLocalizedString(
            "RESTAURANT_PRICE_LEVEL",
            value: "Price level: %@",
            comment: "Format string for a restaurant price level label"
        )

        let localizedPricing: String = {
            switch self {
            case .free:
                return NSLocalizedString(
                    "RESTAURANT_FREE_FOOD",
                    value: "Gratis!",
                    comment: "Price level description for a free restaurant (?)"
                )

            default:
                let moneyString = NSLocalizedString(
                    "RESTAURANT_PRICE_MONEY",
                    value: "💵",
                    comment: "Symbol for some amount of money. Repeated for more expensive restaurants"
                )
                return String(repeating: moneyString, count: self.rawValue)
            }
        }()

        return .localizedStringWithFormat(localizedFormat, localizedPricing)
    }
}
