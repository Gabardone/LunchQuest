//
//  RestaurantsListViewController.swift
//  LunchQuest
//
//  Created by Óscar Morales Vivó on 3/31/23.
//

import SwiftUX
import UIKit

class RestaurantsListViewController: UIComponent<RestaurantsListController> {
    // MARK: - Stored Properties

    enum Section {
        case main
    }

    private let collectionView: UICollectionView = {
        let estimatedHeight = CGFloat(100)
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: layoutSize,
            repeatingSubitem: item,
            count: 1
        )
        group.interItemSpacing = .fixed(10.0)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)

        // Can't really build the collection view properly on IB so we build it all here.
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Restaurant.ID>

    private typealias CellRegistration = UICollectionView.CellRegistration<RestaurantListCell, Restaurant.ID>

    private lazy var dataSource: DataSource = {
        let cellRegistration = CellRegistration { [controller] cell, indexPath, _ in
            cell.configure(restaurant: controller.model.value[indexPath.item])
        }

        return .init(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
    }()

    // MARK: - UIComponent Overrides

    override func updateUI(modelValue: [Restaurant]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Restaurant.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(modelValue.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - UIViewController Overrides

    override func loadView() {
        // Let's save ourselves one extra dummy view in the hierarchy.
        view = collectionView

        collectionView.delegate = self
    }
}

extension RestaurantsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let restaurant = controller.model.value[indexPath.item]
        displayDetailsFor(restaurant: restaurant)

        // Let's not stick the selection.
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
