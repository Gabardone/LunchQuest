//
//  RestaurantsMapViewController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 3/31/23.
//

import MapKit
import SwiftUX
import UIKit

class RestaurantsMapViewController: UIComponent<RestaurantSearchResultsController> {
    init(controller: RestaurantSearchResultsController) {
        super.init(controller: controller, nibName: "RestaurantsMapView")
    }

    // MARK: - IBOutlets

    @IBOutlet
    private var mapView: MKMapView!

    // MARK: - UIComponent Overrides

    override func updateUI(modelValue: RestaurantSearchResults) {
        let annotations = modelValue.restaurants.map { restaurant in
            RestaurantAnnotation(restaurant: restaurant)
        }

        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: false)
    }
}

extension RestaurantsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let restaurantAnnotation = annotation as? RestaurantAnnotation else {
            // Not interested in anything else the user may tap.
            return
        }

        displayDetailsFor(restaurant: restaurantAnnotation.restaurant)
        mapView.deselectAnnotation(annotation, animated: true) // We don't want the selection to stick.
    }
}
