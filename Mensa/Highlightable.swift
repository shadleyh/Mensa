//
//  Highlightable.swift
//  Mensa
//
//  Created by Jordan Kay on 11/27/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public protocol Highlightable {
    associatedtype ViewType: UIView
    
    var highlightView: ViewType! { get }
    func setHighlighted(_ highlighted: Bool, animated: Bool)
}
