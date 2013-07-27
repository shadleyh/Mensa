//
//  Section.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Section of data that can be displayed in a data view.
public struct Section<Item> {
    let title: String?
    let summary: String?
    
    private let items: [Item]
    
    var count: Int {
        return items.count
    }
    
    public init(_ items: [Item], title: String? = nil, summary: String? = nil) {
        self.items = items
        self.title = title
        self.summary = summary
    }
    
    public subscript(index: Int) -> Item {
        return items[index]
    }
}

extension Section: Sequence {
    public func makeIterator() -> AnyIterator<Item> {
        var index = 0
        return AnyIterator {
            if index < self.items.count {
                let object = self.items[index]
                index += 1
                return object
            }
            return nil
        }
    }
}
