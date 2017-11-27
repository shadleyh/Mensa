//
//  DataMediator.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

final class DataMediator<Displayer: DataDisplaying, Identifier>: NSObject, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    typealias Item = Displayer.Item
    typealias View = Displayer.View
    typealias Identifier = Displayer.DataSourceType.Identifier
    
    private let tableViewCellSeparatorInset: CGFloat?
    private let hidesLastTableViewCellSeparator: Bool
    
    private var currentSections: [Section<Item, Identifier>]
    private var registeredIdentifiers = Set<String>()
    private var registeredHeaderFooterViewIdentifiers = Set<String>()
    private var registeredSupplementaryViewIdentifiers = Set<String>()
    private var viewControllerTypes: [String: () -> ItemDisplayingViewController] = Registration.viewControllerTypes
    private var metricsViewControllers: [String: ItemDisplayingViewController] = [:]
    private var sizes: [IndexPath: CGSize] = [:]
    private var heightCache: [String: CGFloat] = [:]
    private var prefetchedCells: [IndexPath: HostingCell]?
    private var needsHandleResting = true
    
    private weak var displayer: Displayer!
    private weak var parentViewController: UIViewController!
    
    init(displayer: Displayer, parentViewController: UIViewController, tableViewCellSeparatorInset: CGFloat?, hidesLastTableViewCellSeparator: Bool) {
        self.displayer = displayer
        self.parentViewController = parentViewController
        self.tableViewCellSeparatorInset = tableViewCellSeparatorInset
        self.hidesLastTableViewCellSeparator = hidesLastTableViewCellSeparator
        currentSections = displayer.dataSource.sections
        super.init()
    }
    
    var sectionCount: Int {
        return currentSections.count
    }
    
    func register<Item, ViewController: UIViewController>(_ itemType: Item.Type, conformedToBy conformingTypes: [Any.Type] = [], with viewControllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        let types = [itemType] + conformingTypes
        for type in types {
            let key = String(describing: type)
            viewControllerTypes[key] = {
                let viewController = viewControllerType.init()
                return ItemDisplayingViewController(viewController)
            }            
        }
    }
    
    func prefetchContent(at indexPaths: [IndexPath], in scrollView: UIScrollView) {
        if prefetchedCells == nil {
            prefetchedCells = [:]
            for indexPath in indexPaths {
                guard currentSections.count > indexPath.section, currentSections[indexPath.section].count > indexPath.row else { return }
                if let tableView = scrollView as? UITableView {
                    prefetchedCells?[indexPath] = self.tableView(tableView, cellForRowAt: indexPath) as? HostingCell
                } else if let collectionView = scrollView as? UICollectionView {
                    prefetchedCells?[indexPath] = self.collectionView(collectionView, cellForItemAt: indexPath) as? HostingCell
                }
            }
        }
    }
    
    func reset() {
        sizes = [:]
        currentSections = displayer.dataSource.sections
        needsHandleResting = true
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return currentSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UITableViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        let hostingCell: HostingCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? HostingCell ?? {
            let hostedViewController = viewController(for: type(of: item as Any))
            let cell = TableViewCell<Item>(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant, reuseIdentifier: identifier)
            if let inset = tableViewCellSeparatorInset {
                cell.separatorInset.left = inset
                cell.layoutMargins.left = inset
            }
            return cell
        }()
        
        guard let cell = hostingCell else { return UITableViewCell() }
        let view = cell.hostedViewController.view as! View
        displayer.use(view, with: item, variant: variant, displayed: false)

        cell.hostedViewController.update(with: item, variant: variant, displayed: true)
        cell.hostedViewController.view.layoutIfNeeded()
        return cell as! UITableViewCell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, _) = info(for: indexPath)
        let type = Swift.type(of: item as Any)
        let key = String(describing: type)
        return heightCache[key] ?? {
            let height: CGFloat
            let controller = viewController(for: type)
            if controller.isItemHeightBasedOnTemplate(displayedWith: variant) {
                controller.loadViewFromNib(for: variant)
                height = controller.view.bounds.height
            } else {
                height = UITableViewAutomaticDimension
            }
            heightCache[key] = height
            return height
        }()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        if case let .average(height) = strategy.heightReference {
            return height
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerFooterView(in: tableView, forSection: section, ofType: .header)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return headerFooterView(in: tableView, forSection: section, ofType: .footer)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.backgroundColor = .clear
    }
    
    // TODO: Header and footer height automatic
    // http://collindonnell.com/2015/09/29/dynamically-sized-table-view-header-or-footer-using-auto-layout/
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canSelectItem(item) ?? false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.selectItem(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.setItemHighlighted(item, highlighted: true, animated: false)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !tableView.isTracking
        cell?.hostedViewController.setItemHighlighted(item, highlighted: false, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let (item, _, _) = info(for: indexPath)
        if editingStyle == .delete {
            displayer.handleDeletion(of: item, at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        guard displayer.canEditSection(indexPath.section) else { return false }
        return cell?.hostedViewController.canRemoveItem(item) ?? false
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let view = (cell as! TableViewCell<Item>).hostedViewController.view as! View
        displayer.use(view, with: item, variant: variant, displayed: true)
        
        cell.backgroundColor = tableView.backgroundColor
        if hidesLastTableViewCellSeparator {
            let isLastCell = (indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
            if isLastCell {
                cell.separatorInset.left = cell.bounds.width
            }
        }
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: tableView)
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UICollectionViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        if !registeredIdentifiers.contains(identifier) {
            collectionView.register(CollectionViewCell<Item>.self, forCellWithReuseIdentifier: identifier)
            registeredIdentifiers.insert(identifier)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CollectionViewCell<Item>
        if !cell.hostingContent {
            let hostedViewController = viewController(for: type(of: item as Any))
            cell.setup(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant)
            print("Setting up cell at \(indexPath) in \(hostedViewController.parent!) for \(type(of: item as Any)).")
        }
        
        cell.hostedViewController.update(with: item, variant: variant, displayed: true)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let type = SectionViewType(collectionElementKind: kind), let supplementaryView = self.supplementaryView(in: collectionView, for: indexPath, ofType: type) else {
            return (nil as UICollectionReusableView?)!
        }
        return supplementaryView
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let view = (cell as! CollectionViewCell<Item>).hostedViewController.view as! View
        displayer.use(view, with: item, variant: variant, displayed: true)
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: collectionView)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.selectItem(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.setItemHighlighted(item, highlighted: true, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !collectionView.isTracking
        cell?.hostedViewController.setItemHighlighted(item, highlighted: false, animated: animated)
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var sectionInsets: UIEdgeInsets = .zero
        let defaultSize = CGSize(width: 50, height: 50)
        let sizeInsets = displayer.sizeInsets(for: indexPath)
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            guard flowLayout.itemSize == defaultSize else {
                let size = flowLayout.itemSize
                return CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            }
            sectionInsets = collectionViewSectionInset(forSection: indexPath.section, with: flowLayout)
        }
        
        return sizes[indexPath] ?? {
            let containerSize = UIEdgeInsetsInsetRect(collectionView.superview!.bounds, sectionInsets).size
            let scrollViewSize = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.scrollIndicatorInsets).size
            let size = viewSize(at: indexPath, withContainerSize: containerSize, scrollViewSize: scrollViewSize)
            let insetSize = CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            sizes[indexPath] = insetSize
            return insetSize
        }()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return collectionViewSectionInset(forSection: section, with: flowLayout)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sizeForSupplementaryView(ofType: .header, inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sizeForSupplementaryView(ofType: .footer, inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.backgroundColor = .clear
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) { displayer.handle(.didScroll) }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { displayer.handle(.willBeginDragging) }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) { displayer.handle(.willEndDragging(velocity: velocity, targetContentOffset: targetContentOffset)) }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { displayer.handle(.willBeginDecelerating) }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { displayer.handle(.willScrollToTop); return true }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) { displayer.handle(.didScrollToTop) }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { displayer.handle(.didEndScrollingAnimation) }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleResting(for: scrollView)
        displayer.handle(.didEndDecelerating)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleResting(for: scrollView)
        }
        displayer.handle(.didEndDragging(decelerate: decelerate))
    }
}

private extension DataMediator {
    func info(for indexPath: IndexPath) -> (Item, DisplayVariant, String) {
        let item = currentSections[indexPath.section][indexPath.row]
        let key = String(describing: type(of: item as Any))
        let variant = displayer.variant(for: item)
        let identifier = key + String(variant.rawValue)
        return (item, variant, identifier)
    }
    
    func identifier(for type: SectionViewType, inSection section: Int) -> String {
        var identifier = "\(type.rawValue)View"
        if let sectionIdentifierName = currentSections[section].identifier?.name {
            identifier = sectionIdentifierName + identifier
        }
        return identifier
    }
    
    func text(for type: SectionViewType, inSection section: Int) -> String? {
        let section = currentSections[section]
        switch type {
        case .header:
            return section.title
        case .footer:
            return section.summary
        }
    }
    
    func detailText(forSection section: Int) -> String? {
        let section = currentSections[section]
        return section.subtitle
    }
    
    func viewController(for type: Any) -> ItemDisplayingViewController {
        let key = String(describing: type)
        return viewControllerTypes[key]!()
    }
    
    func hostedViewController(for cell: UITableViewCell) -> UIViewController? {
        return (cell as? HostingCell)?.hostedViewController
    }
    
    func collectionViewSectionInset(forSection section: Int, with layout: UICollectionViewFlowLayout) -> UIEdgeInsets {
        return displayer.sectionInsets(forSection: section) ?? layout.sectionInset
    }
    
    func viewSize(at indexPath: IndexPath, withContainerSize containerSize: CGSize, scrollViewSize: CGSize) -> CGSize {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        
        var size: CGSize = .zero
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        
        var fittedSize: CGSize? = nil
        if case .constraints = strategy.widthReference, case .constraints = strategy.heightReference {
            metricsViewController.loadViewFromNib(for: variant)
            let metricsView = metricsViewController.view as! View
            displayer.use(metricsView, with: item, variant: variant, displayed: false)
            metricsViewController.update(with: item, variant: variant, displayed: false)
            
            if case .constraints = strategy.heightReference {
                switch strategy.widthReference {
                case .containerView:
                    metricsView.frame.size.width = containerSize.width
                case .scrollView:
                    metricsView.frame.size.width = scrollViewSize.width
                default:
                    break
                }
            } else {
                switch strategy.heightReference {
                case .containerView:
                    metricsView.frame.size.height = containerSize.height
                case .scrollView:
                    metricsView.frame.size.height = scrollViewSize.height
                default:
                    break
                }
            }
            
            metricsView.setNeedsLayout()
            metricsView.layoutIfNeeded()
            fittedSize = metricsView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        
        var templateSize: CGSize? = nil
        switch (strategy.widthReference, strategy.heightReference) {
        case (.template, _), (_, .template):
            templateSize = metricsViewController.sizeOfNib(for: variant)
        default:
            break
        }

        switch strategy.widthReference {
        case .constraints, .average:
            size.width = fittedSize!.width
        case .containerView:
            size.width = containerSize.width
        case .scrollView:
            size.width = scrollViewSize.width
        case .template:
            size.width = templateSize!.width
        }

        switch strategy.heightReference {
        case .constraints, .average:
            size.height = fittedSize!.height
        case .containerView:
            size.height = containerSize.height
        case .scrollView:
            size.height = scrollViewSize.height
        case .template:
            size.height = templateSize!.height
        }
        
        if let margin = strategy.maxContainerMargin {
            size.width = min(size.width, containerSize.width - margin * 2)
        }

        return size
    }
    
    func headerFooterView(in tableView: UITableView, forSection section: Int, ofType type: SectionViewType) -> HeaderFooterView? {
        guard let text = self.text(for: type, inSection: section) else { return nil }
        
        let detailText = self.detailText(forSection: section)
        let identifier = self.identifier(for: type, inSection: section)
        if !registeredHeaderFooterViewIdentifiers.contains(identifier) {
            let nib = UINib(nibName: identifier, bundle: Bundle.main)
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
            registeredHeaderFooterViewIdentifiers.insert(identifier)
        }
        
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? HeaderFooterView else { return nil }
        view.label?.text = text
        view.detailLabel?.text = detailText
        return view
    }
    
    func supplementaryView(in collectionView: UICollectionView, for indexPath: IndexPath, ofType type: SectionViewType) -> SupplementaryView? {
        let section = indexPath.section
        guard let text = self.text(for: type, inSection: section) else { return nil }
        
        let detailText = self.detailText(forSection: section)
        let kind = type.collectionElementKind
        let identifier = self.identifier(for: type, inSection: section)
        if !registeredSupplementaryViewIdentifiers.contains(identifier) {
            let nib = UINib(nibName: identifier, bundle: Bundle.main)
            collectionView.register(nib, forSupplementaryViewOfKind: type.collectionElementKind, withReuseIdentifier: identifier)
            registeredSupplementaryViewIdentifiers.insert(identifier)
        }
        
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? SupplementaryView else { return nil }
        view.label?.text = text
        view.detailLabel?.text = detailText
        return view
    }
    
    func sizeForSupplementaryView(ofType type: SectionViewType, inSection section: Int) -> CGSize {
        guard let text = text(for: type, inSection: section) else { return .zero }
        
        let detailText = self.detailText(forSection: section)
        let identifier = self.identifier(for: type, inSection: section)
        let height = heightCache[identifier] ?? {
            let nib = UINib(nibName: identifier, bundle: Bundle.main)
            let view = nib.instantiate(withOwner: nil, options: nil).first as! SupplementaryView
            view.label?.text = text
            view.detailLabel?.text = detailText
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            let height = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            heightCache[identifier] = height
            return height
        }()
        return CGSize(width: 0, height: height)
    }
    
    func handleResting(for scrollView: UIScrollView) {
        var cells: [HostingCell] = []
        var indexPaths: [IndexPath] = []
        if let tableView = scrollView as? UITableView {
            cells = tableView.visibleCells.map { $0 as! TableViewCell<Item> }
            indexPaths = tableView.indexPathsForVisibleRows!
        } else if let collectionView = scrollView as? UICollectionView {
            cells = collectionView.visibleCells.map { $0 as! CollectionViewCell<Item> }
            indexPaths = collectionView.indexPathsForVisibleItems
        }
        
        for (cell, indexPath) in zip(cells, indexPaths) {
            let (item, _, _) = info(for: indexPath)
            cell.hostedViewController.updateForResting(with: item)
        }
    }
}

private enum SectionViewType: String {
    case header = "Header"
    case footer = "Footer"
}

private extension SectionViewType {
    init?(collectionElementKind: String) {
        switch collectionElementKind {
        case UICollectionElementKindSectionHeader:
            self = .header
        case UICollectionElementKindSectionFooter:
            self = .footer
        default:
            return nil
        }
    }
    
    var collectionElementKind: String {
        switch self {
        case .header:
            return UICollectionElementKindSectionHeader
        case .footer:
            return UICollectionElementKindSectionHeader
        }
    }
}
