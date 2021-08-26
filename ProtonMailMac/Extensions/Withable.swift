//
//  Withable.swift
//  ProtonMailMac
//
//  Created by Marcel Piešťanský on 25.08.2021.
//  Copyright © 2021 marpies. All rights reserved.
//

import Foundation
import AppKit

//
// MARK: - Withable
//

public protocol ObjectWithable: AnyObject {
    
    associatedtype T
    
    /// Provides a closure to configure instances inline.
    /// - Parameter closure: A closure `self` as the argument.
    /// - Returns: Simply returns the instance after called the `closure`.
    @discardableResult func with(_ closure: (_ instance: T) -> Void) -> T
}

public extension ObjectWithable {
    
    @discardableResult func with(_ closure: (_ instance: Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

//
// MARK: - Withable for Values
//

public protocol Withable {
    
    associatedtype T
    
    /// Provides a closure to configure instances inline.
    /// - Parameter closure: A closure with a mutable copy of `self` as the argument.
    /// - Returns: Simply returns the mutated copy of the instance after called the `closure`.
    @discardableResult func with(_ closure: (_ instance: inout T) -> Void) -> T
}

public extension Withable {
    
    @discardableResult func with(_ closure: (_ instance: inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}

extension NSObject: ObjectWithable { }

//
// MARK: - Declarative AppKit
//

public extension NSView {
    
    static var spacer: NSView {
        NSView().with {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentHuggingPriority(.required, for: .vertical)
        }
    }
}


public extension NSStackView {
    
    func horizontal(spacing: CGFloat = 0) -> Self {
        with {
            $0.orientation = .horizontal
            $0.spacing = spacing
        }
    }
    
    func vertical(spacing: CGFloat = 0) -> Self {
        with {
            $0.orientation = .vertical
            $0.spacing = spacing
        }
    }
    
    func views(_ views: NSView ...) -> Self {
        views.forEach { self.addArrangedSubview($0) }
        return self
    }
}
