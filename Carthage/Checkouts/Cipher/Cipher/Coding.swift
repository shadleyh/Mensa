//
//  Coding.swift
//  Cipher
//
//  Created by Jordan Kay on 5/31/17.
//  Copyright © 2017 Squareknot. All rights reserved.
//

public extension NSCoding where Self: NSObject {
    func setProperties(from object: Self) {
        object.properties.forEach { key, value in
            if let value = value {
                setValue(value, forKey: key)
            }
        }
    }
    
    func decodeProperties(from coder: NSCoder, manuallyDecode: () -> Void = {}) {
#if !TARGET_INTERFACE_BUILDER
        guard coder is NSKeyedUnarchiver else { return }
        properties.forEach { key, _ in
            if let value = coder.decodeObject(forKey: key) {
                setValue(value, forKey: key)
            }
        }
        manuallyDecode()
#endif
    }
    
    func encodeProperties(with coder: NSCoder, manuallyEncode: () -> Void = {}) {
#if !TARGET_INTERFACE_BUILDER
        properties.forEach { key, value in
            if self.value(forKey: key) != nil {
                coder.encode(value, forKey: key)
            }
        }
        manuallyEncode()
#endif
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
