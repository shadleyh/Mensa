//
//  Scrolling.swift
//  Mensa
//
//  Created by Jordan Kay on 7/22/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

public enum ScrollEvent {
    case canScroll
    case didScroll
    case willBeginDragging
    case willEndDragging(velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    case didEndDragging(decelerate: Bool)
    case willBeginDecelerating
    case didEndDecelerating
    case didEndScrollingAnimation
    case willScrollToTop
    case didScrollToTop
}

public extension UIScrollView {
    var isScrolledToTop: Bool {
        return contentOffset.y == -contentInset.top
    }
    
    func scrollToTop(animated: Bool) {
        let offset = CGPoint(x: contentOffset.x, y: -contentInset.top)
        
        if animated {
            if delegate?.scrollViewShouldScrollToTop?(self) ?? false {
                setContentOffset(offset, animated: true)
            }
        } else {
            contentOffset = offset
        }
    }
}
