//
//  StringView.swift
//  Mensa
//
//  Created by Jordan Kay on 5/24/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public final class StringView: UIView {
    @IBOutlet public private(set) var label: UIView?
}

extension StringView: Displayed {
    public typealias Item = String
    
    public func update(with string: String, variant: DisplayVariant) {
        (label as? UILabel)?.text = string
        (label as? UITextView)?.text = string
    }
}
