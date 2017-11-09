//
//  ExampleCollectionViewController.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Mensa

final class ExampleCollectionViewController: UIViewController {
    let dataSource = ExampleDataSource(itemCount: .itemCount)
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setDisplayContext()
        view.backgroundColor = .black
    }
}

extension ExampleCollectionViewController: DataDisplaying {
    typealias Item = NumberOrPrimeFlag
    typealias View = UIView
    
    var displayContext: DataDisplayContext {
        let layout = UICollectionViewFlowLayout()
        return .collectionView(layout: layout)
    }
    
    func use(_  view: View, with item: Item, variant: DisplayVariant, displayed: Bool) {
        if let number = item as? Number, let numberView = view as? NumberView {
            let size = CGFloat(.maxFontSize - number.value)
            numberView.valueLabel.font = UIFont.systemFont(ofSize: size)
        }
    }
    
    func variant(for item: Item, viewType: View.Type) -> DisplayVariant {
        if viewType == PrimeFlagView.self {
            return PrimeFlagView.Context.compact
        }
        return DisplayInvariant()
    }
    
    func identifier(forSection section: Int) -> String? {
        return "Foo"
    }
}

private extension Int {
    static let itemCount = 100
    static let maxFontSize = 114
}
