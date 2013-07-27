//
//  ItemSizingStrategy.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Strategy for displaying a single item.
public struct ItemSizingStrategy {
    public enum DimensionReference {
        case constraints
        case containerView
        case scrollView
        case template
        case average(CGFloat)
    }
    
    let widthReference: DimensionReference
    let heightReference: DimensionReference
    let maxContainerMargin: CGFloat?
    
    public init(widthReference: DimensionReference, heightReference: DimensionReference, maxContainerMargin: CGFloat? = nil) {
        self.widthReference = widthReference
        self.heightReference = heightReference
        self.maxContainerMargin = maxContainerMargin
    }
}
