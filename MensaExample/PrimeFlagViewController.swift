//
//  PrimeFlagViewController.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Mensa

final class PrimeFlagViewController: UIViewController, ItemDisplaying {
    typealias Item = PrimeFlag
    typealias View = PrimeFlagView
    typealias DisplayVariantType = PrimeFlagView.Context
    
    func itemSizingStrategy(for primeFlag: PrimeFlag, displayedWith variant: PrimeFlagView.Context) -> ItemSizingStrategy {
        return ItemSizingStrategy(widthReference: .template, heightReference: .template)
    }
}
