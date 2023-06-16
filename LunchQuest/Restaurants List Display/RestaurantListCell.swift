//
//  RestaurantListCellCollectionViewCell.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 4/4/23.
//

import AutoLayoutHelpers
import GlobalDependencies
import Iutilitis
import UIKit

class RestaurantListCell: UICollectionViewListCell {
    private let imageView = buildImageView()

    private let imageLoadingIndicator = UIActivityIndicatorView(style: .medium)

    private let nameLabel = UILabel()

    private let ratingLabel = UILabel()

    private let addressLabel = UILabel()

    // Store the cache ID of a loading image so if it changes it won't overwrite later.
    private var loadingImage: PhotoCacheID?
}

extension RestaurantListCell {
    func configure(restaurant: Restaurant, dependencies: GlobalDependencies = .default) {
        nameLabel.text = restaurant.name

        ratingLabel.text = restaurant.ratingString

        addressLabel.text = restaurant.address

        let scale = UIScreen.main.scale
        let cacheID = restaurant.photo?.cacheID(filling: .init(
            width: Self.imageSize.width * scale,
            height: Self.imageSize.height * scale
        ))

        // Store cache ID for verification on loading task completion (ours or a future one).
        loadingImage = cacheID

        if let cacheID {
            imageView.load { [photoCache = dependencies.photoCache] in
                try await photoCache.cachedValueWith(identifier: cacheID)
            }
        } else {
            imageView.image = nil
        }
    }

    override func prepareForReuse() {
        loadingImage = nil
        imageLoadingIndicator.stopAnimating()
        imageView.image = nil
        nameLabel.text = nil
        ratingLabel.text = nil
        addressLabel.text = nil
    }
}

extension RestaurantListCell {
    override func updateConfiguration(using _: UICellConfigurationState) {
        setupUIIfNeeded()
    }
}

extension RestaurantListCell {
    private static let imageSize = CGSize(width: 100.0, height: 100.0)

    private func setupUIIfNeeded() {
        guard contentView.subviews.count == 0 else {
            return
        }

        var constraints = [NSLayoutConstraint]()
        let verticalStack = UIStackView(arrangedSubviews: [nameLabel, ratingLabel, addressLabel])
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading

        let imageContainer = UIView()
        imageContainer.add(subview: imageView)
        constraints += (
            imageView.constraints(forFixedSize: Self.imageSize) +
                imageView.constraintsAgainstSuperviewEdges()
        )

        imageContainer.add(subview: imageLoadingIndicator)
        constraints += imageLoadingIndicator.constraintsCenteringInSuperview()

        let horizontalStack = UIStackView(arrangedSubviews: [imageContainer, verticalStack])
        horizontalStack.alignment = .top
        horizontalStack.spacing = 8.0 // System default.

        contentView.add(subview: horizontalStack)
        constraints += horizontalStack.constraintsAgainstSuperviewEdges()

        // Activating all the constraints at once is more effective.
        constraints.activate()
    }

    private static func buildImageView() -> ImageLoadingView {
        let imageView = ImageLoadingView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8.0
        return imageView
    }
}
