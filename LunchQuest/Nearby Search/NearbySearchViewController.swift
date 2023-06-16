//
//  ViewController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/10/23.
//

import AutoLayoutHelpers
import Combine
import GlobalDependencies
import Iutilitis
import os
import UIComponents
import UIKit

class NearbySearchViewController: ContainerUIComponent<NearbySearchController> {
    init(controller: NearbySearchController, dependencies: GlobalDependencies = .default) {
        self.dependencies = dependencies
        super.init(controller: controller, nibName: "NearbySearchView", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - IBOutlets

    @IBOutlet var loadingView: UIView!

    @IBOutlet var errorView: UIView!

    @IBOutlet var errorDescriptionLabel: UILabel!

    // MARK: - Stored Properties

    private static let logger = Logger(forClass: NearbySearchViewController.self)

    /**
     Because we're initializing from a storyboard, we leave the dependencies exposed to other module types in case we
     want to override before starting to use them. We'll use `GlobalDependencies.default` if it's not set.
     */
    var dependencies: (any RestaurantPersistenceDependency)?

    private var loadingSubscription: (any Cancellable)?

    // MARK: - ContainerUIComponent Overrides

    override var contentEnclosure: LayoutArea {
        // We're using the safe area layout guide for the contents.
        view.safeAreaLayoutGuide
    }

    // MARK: - UIComponent Overrides

    override func setUpUI() {
        // Set up the search controller
        let searchController = UISearchController(searchResultsController: nil)
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override func updateUI(modelValue: LoadState) {
        // Just updating our local state will do fine.
        switch modelValue {
        case .uninitialized:
            // Wait until something else happens.
            break

        case let .error(newError):
            // Show up the error UI.
            setupErrorDisplay(error: newError)

        case let .success(searchResults):
            // Everything is awesome, show the content and go dormant.
            setupContent(searchResults: searchResults)

        case .done:
            // We're done, nothing more to do here.
            break

        case .loading:
            // We should see this flow happens when starting the first load or when the user retries after error.
            setupLoadingIndicator()
        }
    }
}

// MARK: - IBActions

extension NearbySearchViewController {
    @IBAction
    func retryLoad() {
        // There we go again.
        controller.fetchNearbyRestaurants(searchTerms: searchTerms)
    }
}

// MARK: - UISearchBarDelegate Adoption

extension NearbySearchViewController: UISearchBarDelegate {
    var searchTerms: String? {
        navigationItem.searchController?.searchBar.text
    }

    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // User cleared search, let's reload.
            retryLoad()
        }
    }

    func searchBarTextDidEndEditing(_: UISearchBar) {
        // User entered a string.
        retryLoad()
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        // User explicitly canceled.
        retryLoad()
    }
}

// MARK: - UIViewController Overrides

extension NearbySearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Time to start loading stuff.
        controller.fetchNearbyRestaurants(searchTerms: nil)
    }
}

// MARK: - UI Change Management

extension NearbySearchViewController {
    typealias LoadState = LunchQuest.LoadState<RestaurantSearchResults>

    private func setupLoadingIndicator() {
        loadingView.isHidden = false
        errorView.isHidden = true
        contentViewController?.view.isHidden = true
    }

    private func setupErrorDisplay(error: Error) {
        errorDescriptionLabel.text = error.localizedDescription

        errorView.isHidden = false
        loadingView.isHidden = true
        contentViewController?.view.isHidden = true
    }

    private func setupContent(searchResults: RestaurantSearchResults) {
        let contentViewController = contentViewController ?? {
            let controller = RestaurantSearchResultsController(
                id: UUID(),
                modelProperty: controller.model.searchResultsModel(initialValue: searchResults)
            )

            let contentViewController = NearbySearchResultsViewController(
                controller: controller
            )

            self.contentViewController = contentViewController
            return contentViewController
        }()

        contentViewController.view.isHidden = false
        loadingView.isHidden = true
        errorView.isHidden = true
    }
}
