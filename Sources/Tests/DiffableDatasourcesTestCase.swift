//
//  DiffableDatasourcesTestCase.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 7/30/19.
//  Copyright © 2019 Denys Telezhkin. All rights reserved.
//

import XCTest
@testable import DTCollectionViewManager

@available(iOS 13, tvOS 13, *)
extension NSDiffableDataSourceSnapshot {
    static func snapshot(with block: (inout NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) -> ()) -> NSDiffableDataSourceSnapshot {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        block(&snapshot)
        return snapshot
    }
}

@available(iOS 13, tvOS 13, *)
extension NSDiffableDataSourceSnapshotReference {
    static func snapshot(with block: (NSDiffableDataSourceSnapshotReference) -> ()) -> NSDiffableDataSourceSnapshotReference {
        let snapshot = NSDiffableDataSourceSnapshotReference()
        block(snapshot)
        return snapshot
    }
}

class DiffableDatasourcesTestCase: XCTestCase {
    enum Section {
        case one
        case two
        case three
    }
    var diffableDataSource: Any?
    
    @available(iOS 13, tvOS 13, *)
    var dataSource: UICollectionViewDiffableDataSource<Section, Int>! {
        return diffableDataSource as? UICollectionViewDiffableDataSource<Section, Int>
    }
    var controller = DTCellTestCollectionController()
    
    @available(iOS 13, tvOS 13, *)
    func setItems(_ items: [Int]) {
        dataSource.apply(.snapshot(with: { snapshot in
            snapshot.appendSections([.one])
            snapshot.appendItems(items)
        }))
    }
    
    override func setUp() {
        super.setUp()
        guard #available(iOS 13, tvOS 13, *) else { return }
        let _ = controller.view
        let temp : UICollectionViewDiffableDataSource<Section, Int> =  controller.manager.configureDiffableDataSource(modelProvider: { $1 })
        diffableDataSource = temp
        controller.manager.register(NibCell.self)
    }
    
    func testMultipleSectionsWorkWithDiffableDataSources() {
        guard #available(iOS 13, tvOS 13, *) else { return }
        dataSource.apply(.snapshot(with: { snapshot in
            snapshot.appendSections([.one, .two])
            snapshot.appendItems([1,2], toSection: .one)
            snapshot.appendItems([3,4], toSection: .two)
        }))
        
        XCTAssert(controller.verifyItem(2, atIndexPath: indexPath(1, 0)))
        XCTAssert(controller.verifyItem(3, atIndexPath: indexPath(0, 1)))
        XCTAssertEqual(controller.manager.storage.numberOfSections(), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 1), 2)
    }
    
    func testApplyingDatasourceWithAnimationDoesNotCrashOnXcode13() {
        guard #available(iOS 13, tvOS 13, *) else { return }
        dataSource.apply(.snapshot(with: { snapshot in
            snapshot.appendSections([.one, .two])
            snapshot.appendItems([1,2], toSection: .one)
            snapshot.appendItems([3,4], toSection: .two)
        }), animatingDifferences: true)
        
        XCTAssert(controller.verifyItem(2, atIndexPath: indexPath(1, 0)))
        XCTAssert(controller.verifyItem(3, atIndexPath: indexPath(0, 1)))
        XCTAssertEqual(controller.manager.storage.numberOfSections(), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 1), 2)
        
        let exp = expectation(description: "waiting for Xcode 13 exception to come in")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCellSelectionClosure()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller = ReactingTestCollectionViewController()
        let _ = controller.view
        let temp: UICollectionViewDiffableDataSource<Section, Int> = controller.manager.configureDiffableDataSource(modelProvider: { $1 })
        diffableDataSource = temp
        controller.manager.register(SelectionReactingCollectionCell.self)
        var reactingCell : SelectionReactingCollectionCell?
        controller.manager.didSelect(SelectionReactingCollectionCell.self) { (cell, model, indexPath) in
            cell.indexPath = indexPath
            cell.model = model
            reactingCell = cell
        }
        
        dataSource.apply(.snapshot(with: { snapshot in
            snapshot.appendSections([.one])
            snapshot.appendItems([1,2], toSection: .one)
        }))
        controller.manager.collectionDelegate?.collectionView(controller.collectionView, didSelectItemAt: indexPath(1, 0))
        
        XCTAssertEqual(reactingCell?.indexPath, indexPath(1, 0))
        XCTAssertEqual(reactingCell?.model, 2)
    }
    
    func testShouldShowViewHeaderOnEmptySEction()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerHeader(NibHeaderFooterView.self)
        controller.manager.supplementaryStorage?.setSectionHeaderModels([1])
        setItems([])
        XCTAssertNotNil(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                             viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
                                                                             at: indexPath(0, 0)))
    }
    
    func testShouldShowViewFooterOnEmptySection()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerFooter(NibHeaderFooterView.self)
        controller.manager.supplementaryStorage?.setSectionFooterModels([1])
        setItems([])
        XCTAssertNotNil(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                                     viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter,
                                                                                     at: indexPath(0, 0)))
    }
    
    func testSupplementaryKindsShouldBeSet()
    {
        XCTAssertEqual(controller.manager.supplementaryStorage?.supplementaryHeaderKind, UICollectionView.elementKindSectionHeader)
        XCTAssertEqual(controller.manager.supplementaryStorage?.supplementaryFooterKind, UICollectionView.elementKindSectionFooter)
    }
    
    func testHeaderViewShouldBeCreated()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerHeader(NibHeaderFooterView.self)
        controller.manager.supplementaryStorage?.setSectionHeaderModels([1])
        setItems([1])
        XCTAssert(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                                     viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
                                                                                     at: indexPath(0, 0)) is NibHeaderFooterView)
    }
    
    func testFooterViewShouldBeCreated()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerFooter(NibHeaderFooterView.self)
        controller.manager.supplementaryStorage?.setSectionFooterModels([1])
        setItems([1])
        XCTAssert(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                                     viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter,
                                                                                     at: indexPath(0, 0)) is NibHeaderFooterView)
    }
    
    func testHeaderViewShouldBeCreatedFromXib()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerHeader(NibHeaderFooterView.self) { mapping in
            mapping.xibName = "NibHeaderFooterView"
        }
        controller.manager.supplementaryStorage?.setSectionHeaderModels([1])
        setItems([1])
        XCTAssert(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                                             viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
                                                                                             at: indexPath(0, 0)) is NibHeaderFooterView)
    }
    
    func testFooterViewShouldBeCreatedFromXib()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        controller.manager.registerFooter(NibHeaderFooterView.self) { mapping in
            mapping.xibName = "NibHeaderFooterView"
        }
        controller.manager.supplementaryStorage?.setSectionFooterModels([1])
        setItems([1])
        XCTAssert(controller.manager.collectionDataSource?.collectionView(controller.collectionView,
                                                                                             viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter,
                                                                                             at: indexPath(0, 0)) is NibHeaderFooterView)
    }
    func testWillDisplayHeaderInSection() {
        guard #available(iOS 13, tvOS 13, *) else { return }
        let exp = expectation(description: "willDisplayHeaderInSection")
        controller.manager.registerHeader(ReactingHeaderFooterView.self)
        controller.manager.willDisplayHeaderView(ReactingHeaderFooterView.self, { header, model, section  in
            exp.fulfill()
        })
        controller.manager.supplementaryStorage?.setSectionHeaderModels(["Foo"])
        setItems([])
        _ = controller.manager.collectionDelegate?.collectionView(controller.collectionView,
                                                                  willDisplaySupplementaryView: ReactingHeaderFooterView(),
                                                                  forElementKind: UICollectionView.elementKindSectionHeader,
                                                                  at: indexPath(0, 0))
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testWillDisplayFooterInSection() {
        guard #available(iOS 13, tvOS 13, *) else { return }
        let exp = expectation(description: "willDisplayFooterInSection")
        controller.manager.registerFooter(ReactingHeaderFooterView.self)
        controller.manager.willDisplayFooterView(ReactingHeaderFooterView.self, { footer, model, section  in
            exp.fulfill()
        })
        controller.manager.supplementaryStorage?.setSectionFooterModels(["Foo"])
        setItems([])
        _ = controller.manager.collectionDelegate?.collectionView(controller.collectionView,
                                                                          willDisplaySupplementaryView: ReactingHeaderFooterView(),
                                                                          forElementKind: UICollectionView.elementKindSectionFooter,
                                                                          at: indexPath(0, 0))
        waitForExpectations(timeout: 1, handler: nil)
    }
}

class DiffableDatasourceReferencesTestCase: XCTestCase {
    enum Section {
        case one
        case two
        case three
    }
    
    var diffableDataSourceReference: Any?
    @available(iOS 13, tvOS 13, *)
    var dataSourceReference: UICollectionViewDiffableDataSourceReference! {
        return diffableDataSourceReference as? UICollectionViewDiffableDataSourceReference
    }
    var controller = DTCellTestCollectionController()
    
    override func setUp() {
        super.setUp()
        guard #available(iOS 13, tvOS 13, *) else { return }
        let _ = controller.view
        controller.manager.register(NibCell.self)
        diffableDataSourceReference = controller.manager.configureDiffableDataSource(modelProvider: { $1 })
        controller.manager.register(NibCell.self)
    }
    
    func testMultipleSectionsWorkWithDiffableDataSourceReferences() {
        guard #available(iOS 13, tvOS 13, *) else { return }
        dataSourceReference.applySnapshot(.snapshot(with: { snapshot in
            snapshot.appendSections(withIdentifiers: [Section.one, Section.two])
            snapshot.appendItems(withIdentifiers: [1,2], intoSectionWithIdentifier: Section.one)
            snapshot.appendItems(withIdentifiers: [3,4], intoSectionWithIdentifier: Section.two)
        }), animatingDifferences: false)
        
        XCTAssert(controller.verifyItem(2, atIndexPath: indexPath(1, 0)))
        XCTAssert(controller.verifyItem(3, atIndexPath: indexPath(0, 1)))
        XCTAssertEqual(controller.manager.storage.numberOfSections(), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(controller.manager.storage.numberOfItems(inSection: 1), 2)
    }
    
    func testCellSelectionClosure()
    {
        guard #available(iOS 13, tvOS 13, *) else { return }
        let exp = expectation(description: "cell selection")
        controller = ReactingTestCollectionViewController()
        let _ = controller.view
        diffableDataSourceReference = controller.manager.configureDiffableDataSource(modelProvider: { $1 })
        controller.manager.register(SelectionReactingCollectionCell.self)
        var reactingCell : SelectionReactingCollectionCell?
        controller.manager.didSelect(SelectionReactingCollectionCell.self) { (cell, model, indexPath) in
            cell.indexPath = indexPath
            cell.model = model
            reactingCell = cell
            exp.fulfill()
        }
        
        dataSourceReference.applySnapshot(.snapshot(with: { snapshot in
            snapshot.appendSections(withIdentifiers: [Section.one, Section.two])
            snapshot.appendItems(withIdentifiers: [1,2], intoSectionWithIdentifier: Section.one)
        }), animatingDifferences: true)
        controller.manager.collectionDelegate?.collectionView(controller.collectionView, didSelectItemAt: indexPath(1, 0))
        waitForExpectations(timeout: 1)
        XCTAssertEqual(reactingCell?.indexPath, indexPath(1, 0))
        XCTAssertEqual(reactingCell?.model, 2)
    }
}
