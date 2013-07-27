//
//  DataView.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// UITableView or UICollectionView, used for displaying data.
public protocol DataView: class {
    init()
    func reloadData()

    var frame: CGRect { get set }
    var backgroundColor: UIColor? { get set }
    var autoresizingMask: UIViewAutoresizing { get set }
    var contentOffset: CGPoint { get set }
    var contentInset: UIEdgeInsets { get set }
    var scrollIndicatorInsets: UIEdgeInsets { get set }
    var showsHorizontalScrollIndicator: Bool { get set }
    var showsVerticalScrollIndicator: Bool { get set }
    var isScrollEnabled: Bool { get set }
    var isPagingEnabled: Bool { get set }
    var isDirectionalLockEnabled: Bool { get set }
    var bounces: Bool { get set }
    var alwaysBounceVertical: Bool { get set }
    var alwaysBounceHorizontal: Bool { get set }
}

extension UITableView: DataView {}
extension UICollectionView: DataView {}
