//
//  DisplayVariant.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Values that conform can be used to differentiate between different ways to display a given item.
public protocol DisplayVariant {
    var rawValue: Int { get }
}

/// Used when there is no need to specify a variant.
public struct DefaultDisplayVariant: DisplayVariant {
    public init() {}
    public var rawValue: Int { return 0 }
}

public func ==(lhs: DisplayVariant, rhs: DisplayVariant) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
