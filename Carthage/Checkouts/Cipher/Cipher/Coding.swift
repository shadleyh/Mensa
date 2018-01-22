//
//  Coding.swift
//  Cipher
//
//  Created by Jordan Kay on 5/31/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

public extension NSCoding where Self: NSObject {
    func setProperties(from object: Self) {
        object.properties.forEach { key, value in
            if let value = value {
                if let constraint = value as? NSLayoutConstraint, self.value(forKey: key) == nil {
                    let constraints = (self as! UIView).constraints
                    var existingConstraint: NSLayoutConstraint!
                    if constraint.firstItem === object {
                        existingConstraint = constraints.filter { $0.firstItem === self && $0.secondItem === constraint.secondItem && $0.firstAttribute == constraint.firstAttribute && $0.secondAttribute == constraint.secondAttribute }.first!
                    } else if constraint.secondItem === object {
                        existingConstraint = constraints.filter { $0.secondItem === self && $0.firstItem === constraint.firstItem && $0.firstAttribute == constraint.firstAttribute && $0.secondAttribute == constraint.secondAttribute }.first!
                    }
                    if existingConstraint == nil {
                        setValue(value, forKey: key)
                    } else {
                        setValue(existingConstraint, forKey: key)
                    }
                } else {
                    setValue(value, forKey: key)
                }
            }
        }
    }
    
    func decodeProperties(from coder: NSCoder, manuallyDecode: () -> Void = {}) {
        guard coder is NSKeyedUnarchiver, !isTargetInterfaceBuilder else { return }
        properties.forEach { key, _ in
            if let value = coder.decodeObject(forKey: key) {
                setValue(value, forKey: key)
            }
        }
        manuallyDecode()
    }
    
    func encodeProperties(with coder: NSCoder, manuallyEncode: () -> Void = {}) {
        guard !isTargetInterfaceBuilder else { return }
        properties.forEach { key, value in
            if self.value(forKey: key) != nil {
                coder.encode(value, forKey: key)
            }
        }
        manuallyEncode()
    }
}

extension UIView {
    open override func value(forUndefinedKey key: String) -> Any? { return nil }
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {}
}

private extension NSCoding where Self: NSObject {
    var name: String {
        return String(describing: type(of: self))
    }
    
    var properties: [(String, Any?)] {
        var mirror: Mirror? = Mirror(reflecting: self)
        var propertyKeys: [String] = []
        while mirror != nil {
            propertyKeys += mirror!.children
                .flatMap { $0.label }
                .filter { !$0.contains(".") }
            mirror = mirror?.superclassMirror
        }
        return propertyKeys.map { ($0, value(forKey: $0)) }
    }
}

private var isTargetInterfaceBuilder: Bool {
    guard let identifier = Bundle.main.bundleIdentifier else { return true }
    return identifier.range(of: "com.apple") != nil
}
