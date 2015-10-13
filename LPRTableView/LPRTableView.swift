//
//  LPRTableView.swift
//  LPRTableView
//
//  Objective-C code Copyright (c) 2013 Ben Vogelzang. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import UIKit

public class LPRTableView: UITableView {
    /// The object that acts as the delegate of the receiving table view.
    public weak var longPressReorderDelegate: LPRTableViewDelegate?
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()
    private var initialIndexPath: NSIndexPath?
    private var currentLocationIndexPath: NSIndexPath?
    private var draggingView: UIImageView?
    private var scrollRate = 0.0
    private let animationDuration = NSTimeInterval(0.3)
    private var scrollDisplayLink: CADisplayLink?
    
    /**
    A Bool property that indicates whether long press to reorder is enabled.
    */
    public var longPressReorderEnabled: Bool {
        get {
            return longPressGestureRecognizer.enabled
        }
        set {
            longPressGestureRecognizer.enabled = newValue
        }
    }
    
    public convenience init()  {
        self.init(frame: CGRectZero)
    }
    
    public override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        longPressGestureRecognizer.addTarget(self, action: "longPressGestureRecognized:")
        addGestureRecognizer(longPressGestureRecognizer)
    }
}

extension LPRTableView {
    
    private func canMoveRowAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return dataSource?.tableView?(self, canMoveRowAtIndexPath: indexPath) ?? true
    }
    
    private func cancelGesture() {
        longPressGestureRecognizer.enabled = false
        longPressGestureRecognizer.enabled = true
    }
    
    internal func longPressGestureRecognized(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.locationInView(self)
        let indexPath = indexPathForRowAtPoint(location)
        
        guard isValidMovement(indexPath, gestureRecognizer: gestureRecognizer) else {
            cancelGesture()
            return
        }
        
        switch gestureRecognizer.state {
        case .Began:
            // Started.
            longPressBegan(gestureRecognizer)
        case .Changed:
            // Dragging.
            longPressChanged(gestureRecognizer)
            break
        case .Ended:
            longPressEnded(gestureRecognizer)
            break
        default:
            break
        }
    }
    
    public func shouldMoveRowAtIndexPath(indexPath: NSIndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
    
    private func longPressBegan(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.locationInView(self)
        guard let indexPath = indexPathForRowAtPoint(location) else {
            return
        }
        guard var cell = cellForRowAtIndexPath(indexPath) else {
            return
        }
        cell.setSelected(false, animated: false)
        cell.setHighlighted(false, animated: false)
        
        if draggingView == nil {
            // Create the view that will be dragged around the screen.
            if let draggingCell = longPressReorderDelegate?.tableView(self, draggingCell: cell, atIndexPath: indexPath) {
                cell = draggingCell
            }
            
            // Make an image from the pressed table view cell.
            UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, UIScreen.mainScreen().scale)
            cell.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            draggingView = UIImageView(image: image)
            
            guard let draggingView = draggingView else {
                // cannot come here
                return
            }
            
            addSubview(draggingView)
            let rect = rectForRowAtIndexPath(indexPath)
            draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y)
            
            longPressReorderDelegate?.tableView(self, willAppearDraggingView: draggingView, atIndexPath: indexPath)
            UIView.animateWithDuration(animationDuration) { [unowned self] in
                // Add drop shadow to image and lower opacity.
                draggingView.layer.masksToBounds = false
                draggingView.layer.shadowColor = UIColor.blackColor().CGColor
                draggingView.layer.shadowOffset = CGSizeZero
                draggingView.layer.shadowRadius = 4.0
                draggingView.layer.shadowOpacity = 0.7
                draggingView.layer.opacity = 0.85
                draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1)
                draggingView.center = CGPointMake(self.center.x, location.y)
            }
        }
        
        cell.hidden = true
        currentLocationIndexPath = indexPath
        initialIndexPath = indexPath
        
        // Enable scrolling for cell.
        scrollDisplayLink = CADisplayLink(target: self, selector: "scrollTableView:")
        scrollDisplayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    private func longPressChanged(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.locationInView(self)
        if let draggingView = draggingView {
            // Update position of the drag view, but don't let it go past the top or the bottom too far.
            if location.y >= 0 && location.y <= contentSize.height + 50 {
                draggingView.center = CGPoint(x: center.x, y: location.y)
            }
        }
        var rect = bounds
        // Adjust rect for content inset, as we will use it below for calculating scroll zones.
        rect.size.height -= contentInset.top
        
        updateCurrentLocation(gestureRecognizer)
        
        // Tell us if we should scroll, and in which direction.
        let scrollZoneHeight = rect.size.height / 6.0
        let topScrollBeginning = contentOffset.y + contentInset.top  + scrollZoneHeight
        let bottomScrollBeginning = contentOffset.y + contentInset.top + rect.size.height - scrollZoneHeight
        
        if location.y >= bottomScrollBeginning {
            // We're in the bottom zone.
            scrollRate = Double(location.y - bottomScrollBeginning) / Double(scrollZoneHeight)
        } else if location.y <= topScrollBeginning {
            // We're in the top zone.
            scrollRate = Double(location.y - topScrollBeginning) / Double(scrollZoneHeight)
        } else {
            scrollRate = 0.0
        }
    }
    
    private func longPressEnded(gestureRecognizer: UILongPressGestureRecognizer) {
        // Remove scrolling CADisplayLink.
        scrollDisplayLink?.invalidate()
        scrollDisplayLink = nil
        scrollRate = 0.0
        
        guard let draggingView = draggingView, currentLocationIndexPath = currentLocationIndexPath else {
            return
        }
        
        // Animate the drag view to the newly hovered cell.
        longPressReorderDelegate?.tableView(self, willDisappearDraggingView: draggingView, atIndexPath: currentLocationIndexPath)
        UIView.animateWithDuration(animationDuration,
            animations: { [unowned self] in
                let rect = self.rectForRowAtIndexPath(currentLocationIndexPath)
                draggingView.transform = CGAffineTransformIdentity
                draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y)
            },
            completion: { [unowned self] _ in
                self.draggingView?.removeFromSuperview()
                if let indexPathsForVisibleRows = self.indexPathsForVisibleRows {
                    self.reloadRowsAtIndexPaths(indexPathsForVisibleRows, withRowAnimation: .None)
                }
                self.currentLocationIndexPath = nil
                self.draggingView = nil
        })
    }
    
    private func isValidMovement(indexPath: NSIndexPath?, gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        // Get out of here if the long press was not on a valid row or our table is empty or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row.
        let numberOfRows = (0..<numberOfSections).reduce(0) { $0 + numberOfRowsInSection($1) }
        guard numberOfRows > 0 else {
            // Table is empty
            return false
        }
        switch gestureRecognizer.state {
        case .Began:
            if indexPath == nil || // Invalid row
                !canMoveRowAtIndexPath(indexPath!) || // Datasource decision
                !shouldMoveRowAtIndexPath(indexPath!, forGestureRecognizer: gestureRecognizer) { // For gesture value
                    return false
            }
        case .Ended:
            if currentLocationIndexPath == nil {
                return false
            }
        default:
            break
        }
        return true
    }
    
    private func updateCurrentLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.locationInView(self)
        guard var indexPath = indexPathForRowAtPoint(location) else {
            return
        }
        if let initialIndexPath = initialIndexPath {
            if let targetIndexPath = delegate?.tableView?(self, targetIndexPathForMoveFromRowAtIndexPath: initialIndexPath, toProposedIndexPath: indexPath) {
                indexPath = targetIndexPath
            }
        }
        if let currentLocationIndexPath = currentLocationIndexPath {
            let oldHeight = rectForRowAtIndexPath(currentLocationIndexPath).size.height
            let newHeight = rectForRowAtIndexPath(indexPath).size.height
            
            
            let cell = cellForRowAtIndexPath(indexPath)
            if indexPath != currentLocationIndexPath && gestureRecognizer.locationInView(cell).y > (newHeight - oldHeight) && canMoveRowAtIndexPath(indexPath) {
                beginUpdates()
                moveRowAtIndexPath(currentLocationIndexPath, toIndexPath: indexPath)
                dataSource?.tableView?(self, moveRowAtIndexPath: currentLocationIndexPath, toIndexPath: indexPath)
                self.currentLocationIndexPath = indexPath
                endUpdates()
            }
        }
    }
    
    internal func scrollTableView(sender: CADisplayLink) {
        let location = longPressGestureRecognizer.locationInView(self)
        guard location.x.isNaN || location.y.isNaN else {
            // Explicitly check for out-of-bound touch
            return
        }
        let offsetY = Double(contentOffset.y) + scrollRate * 10.0
        var newOffset = CGPoint(x: contentOffset.x, y: CGFloat(offsetY))
        
        if newOffset.y < -contentInset.top {
            newOffset.y = -contentInset.top
        } else if (contentSize.height + contentInset.bottom) < frame.size.height {
            newOffset = contentOffset
        } else if newOffset.y > (contentSize.height + contentInset.bottom - frame.size.height) {
            newOffset.y = contentSize.height + contentInset.bottom - frame.size.height
        }
        contentOffset = newOffset
        
        if let draggingView = draggingView {
            if location.y >= 0 && location.y <= (contentSize.height + 50) {
                draggingView.center = CGPoint(x: center.x, y: location.y)
            }
        }
        
        updateCurrentLocation(longPressGestureRecognizer)
    }
}
