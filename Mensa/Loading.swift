//
//  Loading.swift
//  Mensa
//
//  Created by Jordan Kay on 9/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public struct LoadingItem {
    public init() {}
}

public class LoadingItemView: UIView {
    @IBOutlet public private(set) var indicatorView: UIActivityIndicatorView!
}

extension LoadingItemView: Displayed {
    public func update(with loadingItem: LoadingItem, variant: DisplayInvariant) {}
}

public final class LoadingItemViewController: UIViewController {}

extension LoadingItemViewController: ItemDisplaying {
    public typealias Item = LoadingItem
    public typealias View = LoadingItemView
    
    public func isItemHeightBasedOnTemplate(displayedWith variant: DisplayInvariant) -> Bool {
        return true
    }
}
