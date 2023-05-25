//
//  SceneDelegate.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 1/10/23.
//

import MiniDePin
import SwiftUX
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /**
     These are the app's root dependencies, modify this logic or change them before they get passed along if you want
     the app to run on modified global dependencies.
     */
    private lazy var dependencies: RestaurantPersistenceDependency & LocationDependency = GlobalDependencies.default

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene
        // `scene`. If using a storyboard, the `window` property will automatically be initialized and attached to the
        // scene. This delegate does not imply the connecting scene or session are new
        // (see `application:configurationForConnectingSceneSession` instead).
        // guard let scene = (scene as? UIWindowScene) else { return }
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        // Initialize the location dependency (needs to happen on the main thread).
        _ = dependencies.locationManager

        // Initialize the controller.
        let searchController = NearbySearchController(
            id: UUID(),
            model: WritableProperty.root(initialValue: .uninitialized),
            persistence: dependencies.restaurantPersistence
        )

        // Initialize the initial loading view controller.
        let loadViewController = NearbySearchViewController(
            controller: searchController,
            dependencies: dependencies.buildGlobal()
        )
        loadViewController.title = NSLocalizedString(
            "MAIN_TITLE",
            value: "LunchQuest",
            comment: "Title for the main content of the app."
        )

        // Set up the window and its root with a navigation controller that displays the loading view controller.
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: loadViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
