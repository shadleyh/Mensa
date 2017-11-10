//
//  Displaying.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Displays a single item using a view, updating the view based on the item’s properties.
public protocol ItemDisplaying: Displaying {
    func update(with item: Item, variant: DisplayVariantType, displayed: Bool)
    func updateForResting(with item: Item)
    func selectItem(_ item: Item)
    func canSelectItem(_ item: Item) -> Bool
    func canRemoveItem(_ item: Item) -> Bool
    func setItemHighlighted(_ item: Item, highlighted: Bool, animated: Bool)
    func hostsWithConstraints(displayedWith variant: DisplayVariantType) -> Bool
    func isItemHeightBasedOnTemplate(displayedWith variant: DisplayVariantType) -> Bool
    func itemSizingStrategy(for item: Item, displayedWith variant: DisplayVariantType) -> ItemSizingStrategy
}

public extension ItemDisplaying {
    func selectItem(_ item: Item) {}
    func updateForResting(with item: Item) {}
    func canSelectItem(_ item: Item) -> Bool { return true }
    func canRemoveItem(_ item: Item) -> Bool { return false }
    func setItemHighlighted(_ item: Item, highlighted: Bool, animated: Bool) {}
    func hostsWithConstraints(displayedWith variant: DisplayVariantType) -> Bool { return false }
    func isItemHeightBasedOnTemplate(displayedWith variant: DisplayVariantType) -> Bool { return false }
    
    func itemSizingStrategy(for item: Item, displayedWith variant: DisplayVariantType) -> ItemSizingStrategy {
        return ItemSizingStrategy(widthReference: .constraints, heightReference: .constraints)
    }
}

public extension ItemDisplaying where Self: UIViewController {
    var view: View {
        return view as! View
    }
}

public extension ItemDisplaying where Self: UIViewController, View: Displayed, Item == View.Item, DisplayVariantType == View.DisplayVariantType {
    func update(with item: Item, variant: DisplayVariantType, displayed: Bool) {
        (view as? Preparable)?.prepare()
        if displayed {
            view.update(with: item, variant: variant)
        }
    }
}
