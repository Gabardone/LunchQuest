//
//  NearbySearchResultsViewController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 3/30/23.
//

import AutoLayoutHelpers
import SwiftUX
import UIKit

class NearbySearchResultsViewController: ContainerUIComponent<RestaurantSearchResultsController> {
    init(controller: RestaurantSearchResultsController) {
        // Just redirect to the right nib and stuff.
        let listController = RestaurantsListController(
            id: UUID(),
            modelProperty: controller.model.readOnlyKeyPath(\.restaurants)
        )
        self.restaurantsListViewController = RestaurantsListViewController(controller: listController)
        super.init(controller: controller, nibName: "NearbySearchResultsView", bundle: nil)
    }

    // MARK: - Types

    enum Display: Equatable {
        case list
        case map
    }

    // MARK: - IBOutlets

    @IBOutlet
    private var emptyResultsPane: UIView!

    @IBOutlet
    private var toggleDisplayButton: UIButton!

    @IBOutlet
    private var contentView: UIView!

    // MARK: - Stored Properties

    var display: Display = .list {
        didSet {
            guard display != oldValue else {
                return
            }

            updateUI(display: display)
        }
    }

    // MARK: - Stored Properties

    // We're always going to have this one around.
    private let restaurantsListViewController: RestaurantsListViewController

    private var restaurantsMapViewController: RestaurantsMapViewController?

    // MARK: - UIComponent Overrides

    override func setUpUI() {
        // Can't set this stuff in IB.
        emptyResultsPane.backgroundColor = .white.withAlphaComponent(0.8)
        emptyResultsPane.layer.cornerRadius = 20.0

        updateUI(display: display)
    }

    override func updateUI(modelValue: RestaurantSearchResults) {
        // The only thing we manage here is whether to show the empty results panel.
        emptyResultsPane.isHidden = !modelValue.restaurants.isEmpty
    }

    override var contentSuperview: UIView {
        contentView
    }
}

// MARK: - IBActions

extension NearbySearchResultsViewController {
    @IBAction
    private func toggleDisplay() {
        display = {
            switch display {
            case .list:
                return .map

            case .map:
                return .list
            }
        }()
    }
}

// MARK: - UI Utilities

extension NearbySearchResultsViewController {
    private func updateUI(display: Display) {
        let buttonTitle = {
            switch display {
            case .list:
                return NSLocalizedString(
                    "DISPLAY_MAP",
                    value: "Display map",
                    comment: "button title for toggling from list to map display of search results."
                )

            case .map:
                return NSLocalizedString(
                    "DISPLAY_LIST",
                    value: "Display list",
                    comment: "button title for toggling from map to list display of search results."
                )
            }
        }()
        toggleDisplayButton.setTitle(buttonTitle, for: .normal)

        contentViewController = {
            switch display {
            case .list:
                return restaurantsListViewController

            case .map:
                return restaurantsMapViewController ?? {
                    let restaurantsMapViewController = RestaurantsMapViewController(controller: controller)
                    self.restaurantsMapViewController = restaurantsMapViewController
                    return restaurantsMapViewController
                }()
            }
        }()
    }
}
