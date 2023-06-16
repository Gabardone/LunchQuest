//
//  RestaurantDetailsViewController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 5/9/23.
//

import AutoLayoutHelpers
import GlobalDependencies
import Iutilitis
import SwiftUX
import UIComponents
import UIKit

class RestaurantDetailsViewController: UIComponent<RestaurantController> {
    init(controller: RestaurantController, dependencies: GlobalDependencies = .default) {
        self.dependencies = dependencies

        super.init(controller: controller, nibName: "RestaurantDetailsView")
    }

    // MARK: - IBOutlets

    @IBOutlet
    private var imageView: ImageLoadingView!

    @IBOutlet
    private var labelStack: UIStackView!

    @IBOutlet
    private var nameLabel: UILabel!

    @IBOutlet
    private var urlLabel: UILabel!

    @IBOutlet
    private var priceLevelLabel: UILabel!

    @IBOutlet
    private var ratingLabel: UILabel!

    @IBOutlet
    private var addressLabel: UILabel!

    // MARK: - Stored Properties

    private let dependencies: PhotoCacheDependency

    @ActiveConstraint
    private var imageAspectRatio: NSLayoutConstraint?

    // MARK: - UIComponent Overrides

    override func setUpUI() {
        navigationItem.largeTitleDisplayMode = .always

        labelStack.isLayoutMarginsRelativeArrangement = true // This doesn't appear to be settable in IB?
    }

    override func updateUI(modelValue: Restaurant) {
        // We're using large title with the restaurant's name.
        title = modelValue.name

        // Redundant but the title doesn't do shrinkage or multiline.
        nameLabel.text = modelValue.name

        if let website = modelValue.website {
            urlLabel.attributedText = NSAttributedString(string: "\(website.absoluteString)", attributes: [.link: website])
            urlLabel.isHidden = true
        } else {
            urlLabel.text = nil
            urlLabel.isHidden = true
        }

        priceLevelLabel.text = modelValue.priceLevel.map(\.priceString)
        priceLevelLabel.isHidden = modelValue.priceLevel == nil

        ratingLabel.text = modelValue.ratingString

        addressLabel.text = modelValue.address
        addressLabel.isHidden = !modelValue.address.hasContents

        let aspectRatio = modelValue.photo?.originalSize.aspectRatio ?? 1.0
        imageAspectRatio = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio)

        if let cacheID = modelValue.photo.map({ photo in
            PhotoCacheID(id: photo.id, maxSize: .width(Int(UIScreen.main.nativeBounds.width.rounded())))
        }) {
            imageView.load { [photoCache = dependencies.photoCache] in
                try await photoCache.cachedValueWith(identifier: cacheID)
            }
        } else {
            imageView.image = nil
        }
    }
}

extension UIViewController {
    /**
     Simple wrapper for creating a read-only `RestaurantController` (for the time being we will be making them
     standalone as we don't expect editing nor external change management) and displaying it on top of the current
     navigation stack.
     - Parameter restaurant: The restaurant value we want to display.
     */
    func displayDetailsFor(restaurant: Restaurant) {
        // Use a root property for ease.
        let restaurantController = RestaurantController(
            id: restaurant.id,
            modelProperty: WritableProperty.root(initialValue: restaurant).readonly()
        )
        let restaurantViewController = RestaurantDetailsViewController(controller: restaurantController)
        navigationController?.pushViewController(restaurantViewController, animated: true)
    }
}
