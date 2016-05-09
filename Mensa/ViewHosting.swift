//
//  ViewHosting.swift
//  Mensa
//
//  Created by Jordan Kay on 8/4/15.
//  Copyright © 2015 Jordan Kay. All rights reserved.
//

import UIKit

public typealias CellClass = AnyCell.Type

func loadHostedViewForObject<Object, View: UIView, Cell: HostingCell where Object == Cell.ObjectType, View == Cell.ViewType>(object: Object, inCell cell: Cell) {
    let hostedView = cell.hostedViewController.view
    hostedView.frame = cell.hostingView.bounds
    hostedView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    cell.hostingView.addSubview(hostedView)
}

func setParentViewContoller<Object, View: UIView, Cell: HostingCell, ViewController: UIViewController where Object == Cell.ObjectType, View == Cell.ViewType>(parentViewController: ViewController, forCell cell: Cell, withObject object: Object) {
    let hostedViewController = cell.hostedViewController
    if let existingViewController = cell.parentViewController {
        if existingViewController == parentViewController {
            return
        }
        
        let hostedView = hostedViewController.view
        hostedViewController.willMoveToParentViewController(nil)
        hostedView.removeFromSuperview()
        hostedViewController.removeFromParentViewController()
    }
    
    cell.parentViewController = parentViewController
    parentViewController.addChildViewController(hostedViewController)
    loadHostedViewForObject(object, inCell: cell)
    hostedViewController.didMoveToParentViewController(parentViewController)
}

func adjustLayoutConstraintsForCell<Object, Cell: HostingCell where Object == Cell.ObjectType, Cell.ViewType: UIView>(cell: Cell, object: Object) {
    adjustLayoutConstraintsForCell(cell, forObject: object, toPriority: UILayoutPriorityDefaultHigh)
}

private func adjustLayoutConstraintsForCell<Object, Cell: HostingCell where Object == Cell.ObjectType, Cell.ViewType: UIView>(cell: Cell, forObject object: Object, toPriority priority: UILayoutPriority) {
    let hostedView = cell.hostedViewController.view
    for constraint in hostedView.constraints {
        constraint.priority = priority
    }
}

public protocol HostingViewController {
    typealias ObjectType
    typealias ViewType: UIView
    
    static func registerViewControllers() throws
    static func registerViewControllerClass<Object, View: UIView>(viewControllerClass: HostedViewController<Object, View>.Type, forModelType modelType: Object.Type) throws
}

public protocol HostingCell: AnyCell {
    typealias ObjectType
    typealias ViewType: UIView
    
    var hostingView: UIView { get }
    var hostedViewController: HostedViewController<ObjectType, ViewType> { get }
    var layoutInsets: UIEdgeInsets { get set }
    weak var parentViewController: UIViewController? { get set }
}

extension HostingCell {
    public static func subclassWithViewControllerClass(viewControllerClass: HostedViewController<ObjectType, ViewType>.Type, modelType: ObjectType.Type, nibName: String, variant: Int) -> CellClass {
        let bundle = NSBundle(forClass: self)
        let className = TypeKey<Any>(self, viewControllerClass, modelType, variant).description
        var subclass: AnyClass? = NSClassFromString(className)
        if subclass == nil {
            subclass = objc_allocateClassPair(self, className.cStringUsingEncoding(NSUTF8StringEncoding)!, 0)
            let block: @convention(block) AnyObject -> UIViewController = { _ in
                let viewController = (viewControllerClass as UIViewController.Type).init()
                let contents = bundle.loadNibNamed(nibName, owner: viewController, options: nil)
                viewController.view = contents[variant] as! UIView
                return viewController
            }
            let implementation = imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
            
            class_addMethod(subclass, "hostedViewController", implementation, "#@:")
            objc_registerClassPair(subclass)
        }
        return subclass as! CellClass
    }
}

@objc public protocol AnyCell {
    var contentView: UIView { get }
    func addConstraint(constraint: NSLayoutConstraint)
}

extension UITableViewCell: AnyCell {}
extension UICollectionViewCell: AnyCell {}
