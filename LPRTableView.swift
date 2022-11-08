//
//  LPRTableView.swift
//  LPRTableView
//
//  Objective-C code Copyright (c) 2013 Ben Vogelzang. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import QuartzCore
import UIKit

/// The delegate of a `LPRTableView` object can adopt the `LPRTableViewDelegate` protocol.
/// Optional methods of the protocol allow the delegate to modify a cell visually before dragging occurs, or to be notified when a cell is about to be dragged or about to be dropped.
@objc
public protocol LPRTableViewDelegate: NSObjectProtocol {
    
    /// Asks the delegate whether a given row can be moved to another location in the table view based on the gesture location.
    ///
    /// The default is `true`.
    @objc optional func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath indexPath: IndexPath, forDraggingGesture gesture: UILongPressGestureRecognizer) -> Bool
    
    /// Provides the delegate a chance to modify the cell visually before dragging occurs.
    ///
    /// Defaults to using the cell as-is if not implemented.
    @objc optional func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, at indexPath: IndexPath) -> UITableViewCell
    
    /// Called within an animation block when the dragging view is about to show.
    @objc optional func tableView(_ tableView: UITableView, showDraggingView view: UIView, at indexPath: IndexPath)
    
    /// Called within an animation block when the dragging view is about to hide.
    @objc optional func tableView(_ tableView: UITableView, hideDraggingView view: UIView, at indexPath: IndexPath)
    
    /// Called when the dragging gesture's vertical location changes.
    @objc optional func tableView(_ tableView: UITableView, draggingGestureChanged gesture: UILongPressGestureRecognizer)
    
}

open class LPRTableView: UITableView {
    
    /// The object that acts as the delegate of the receiving table view.
    weak open var longPressReorderDelegate: LPRTableViewDelegate?
    
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    fileprivate var initialIndexPath: IndexPath?
    
    fileprivate var currentLocationIndexPath: IndexPath?
    
    fileprivate var draggingView: UIView?
    
    fileprivate var scrollRate: Double = 0.0
    
    fileprivate var scrollDisplayLink: CADisplayLink?
    
    fileprivate var feedbackGenerator: AnyObject?
    
    fileprivate var previousGestureVerticalPosition: CGFloat?
    
    /// A Bool property that indicates whether long press to reorder is enabled.
    open var longPressReorderEnabled: Bool {
        get {
            return longPressGestureRecognizer.isEnabled
        }
        set {
            longPressGestureRecognizer.isEnabled = newValue
        }
    }
    
    /// The minimum period a finger must press on a cell for the reordering to begin.
    ///
    /// The time interval is in seconds. The default duration is `0.5` seconds.
    open var minimumPressDuration: TimeInterval {
        get {
            return longPressGestureRecognizer.minimumPressDuration
        }
        set {
            longPressGestureRecognizer.minimumPressDuration = newValue
        }
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LPRTableView._longPress(_:)))
        longPressGestureRecognizer.delegate = self
        addGestureRecognizer(longPressGestureRecognizer)
    }
    
}

extension LPRTableView: UIGestureRecognizerDelegate {
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == longPressGestureRecognizer else { return true }
        let location: CGPoint = gestureRecognizer.location(in: self)
        let indexPath: IndexPath? = indexPathForRow(at: location)
        let rows: Int = (0..<numberOfSections).reduce(0, { $0 + numberOfRows(inSection: $1) })
        // Long press gesture should not begin if it was not on a valid row or our table is empty
        // or the `dataSource.tableView(_:canMoveRowAt:)` doesn't allow moving the row.
        return (rows > 0)
            && (indexPath != nil)
            && canMoveRowAt(indexPath: indexPath!)
            && shouldMoveRowAt(indexPath: indexPath!, forDraggingGesture: longPressGestureRecognizer)
    }
    
}

extension LPRTableView {
    
    fileprivate func canMoveRowAt(indexPath: IndexPath) -> Bool {
        return dataSource?.tableView?(self, canMoveRowAt: indexPath) ?? true
    }
    
    fileprivate func shouldMoveRowAt(indexPath: IndexPath, forDraggingGesture gesture: UILongPressGestureRecognizer) -> Bool {
        return longPressReorderDelegate?.tableView?(self, shouldMoveRowAtIndexPath: indexPath, forDraggingGesture: longPressGestureRecognizer) ?? true
    }
    
    @objc internal func _longPress(_ gesture: UILongPressGestureRecognizer) {
        let location: CGPoint = gesture.location(in: self)
        let indexPath: IndexPath? = indexPathForRow(at: location)
        
        switch gesture.state {
        case .began: // Started
            hapticFeedbackSetup()
            hapticFeedbackSelectionChanged()
            previousGestureVerticalPosition = location.y
            
            guard let indexPath: IndexPath = indexPath,
                  var cell: UITableViewCell = cellForRow(at: indexPath) else { break }
            endEditing(true)
            cell.setSelected(false, animated: false)
            cell.setHighlighted(false, animated: false)
            
            // Create the view that will be dragged around the screen.
            if draggingView == nil {
                if let draggingCell: UITableViewCell = longPressReorderDelegate?.tableView?(self, draggingCell: cell, at: indexPath) {
                    cell = draggingCell
                }
                
                // Take a snapshot of the pressed table view cell.
                draggingView = cell.snapshotView(afterScreenUpdates: false)
                
                if let draggingView: UIView = draggingView {
                    addSubview(draggingView)
                    let rect: CGRect = rectForRow(at: indexPath)
                    draggingView.frame = draggingView.bounds.offsetBy(dx: rect.origin.x, dy: rect.origin.y)
                    
                    UIView.beginAnimations("LongPressReorder-ShowDraggingView", context: nil)
                    longPressReorderDelegate?.tableView?(self, showDraggingView: draggingView, at: indexPath)
                    UIView.commitAnimations()
                    
                    // Add drop shadow to image and lower opacity.
                    draggingView.layer.masksToBounds = false
                    draggingView.layer.shadowColor = UIColor.black.cgColor
                    draggingView.layer.shadowOffset = .zero
                    draggingView.layer.shadowRadius = 4.0
                    draggingView.layer.shadowOpacity = 0.7
                    draggingView.layer.opacity = 0.85
                    
                    // Zoom image towards user.
                    UIView.beginAnimations("LongPressReorder-Zoom", context: nil)
                    draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    draggingView.center = CGPoint(x: center.x, y: newYCenter(for: draggingView, with: location))
                    UIView.commitAnimations()
                }
            }
            
            cell.isHidden = true
            currentLocationIndexPath = indexPath
            initialIndexPath = indexPath
            
            // Enable scrolling for cell.
            scrollDisplayLink = CADisplayLink(target: self, selector: #selector(LPRTableView._scrollTableWithCell(_:)))
            scrollDisplayLink?.add(to: .main, forMode: .default)
        case .changed: // Dragging
            if let draggingView: UIView = draggingView {
                // Update position of the drag view
                draggingView.center = CGPoint(x: center.x, y: newYCenter(for: draggingView, with: location))
                if let previousGestureVerticalPosition: CGFloat = self.previousGestureVerticalPosition {
                    if location.y != previousGestureVerticalPosition {
                        longPressReorderDelegate?.tableView?(self, draggingGestureChanged: gesture)
                        self.previousGestureVerticalPosition = location.y
                    }
                } else {
                    longPressReorderDelegate?.tableView?(self, draggingGestureChanged: gesture)
                    self.previousGestureVerticalPosition = location.y
                }
            }
            
            let inset: UIEdgeInsets
            if #available(iOS 11.0, *) {
                inset = adjustedContentInset
            } else {
                inset = contentInset
            }
            
            var rect: CGRect = bounds
            // Adjust rect for content inset, as we will use it below for calculating scroll zones.
            rect.size.height -= inset.top
            
            // Tell us if we should scroll, and in which direction.
            let scrollZoneHeight: CGFloat = rect.size.height / 6.0
            let bottomScrollBeginning: CGFloat = contentOffset.y + inset.top + rect.size.height - scrollZoneHeight
            let topScrollBeginning: CGFloat = contentOffset.y + inset.top + scrollZoneHeight
            
            if location.y >= bottomScrollBeginning {
                // We're in the bottom zone.
                scrollRate = Double(location.y - bottomScrollBeginning) / Double(scrollZoneHeight)
            } else if location.y <= topScrollBeginning {
                // We're in the top zone.
                scrollRate = Double(location.y - topScrollBeginning) / Double(scrollZoneHeight)
            } else {
                scrollRate = 0.0
            }
        case .ended where currentLocationIndexPath != nil, // Dropped
             .cancelled,
             .failed:
            // Remove previously cached Gesture location
            self.previousGestureVerticalPosition = nil
            
            // Remove scrolling CADisplayLink.
            scrollDisplayLink?.invalidate()
            scrollDisplayLink = nil
            scrollRate = 0.0
            
            //
            // For use only with Xcode UI Testing:
            // Set launch argument `"-LPRTableViewUITestingScreenshots", "1"` to disable dropping a cell,
            // to facilitate taking a screenshot with a hovering cell.
            //
            guard !UserDefaults.standard.bool(forKey: "LPRTableViewUITestingScreenshots") else { break }
            
            // Animate the drag view to the newly hovered cell.
            UIView.animate(withDuration: 0.3, animations: {
                guard let draggingView: UIView = self.draggingView,
                      let currentLocationIndexPath: IndexPath = self.currentLocationIndexPath else { return }
                UIView.beginAnimations("LongPressReorder-HideDraggingView", context: nil)
                self.longPressReorderDelegate?.tableView?(self, hideDraggingView: draggingView, at: currentLocationIndexPath)
                UIView.commitAnimations()
                let rect: CGRect = self.rectForRow(at: currentLocationIndexPath)
                draggingView.transform = .identity
                draggingView.frame = draggingView.bounds.offsetBy(dx: rect.origin.x, dy: rect.origin.y)
            }, completion: { (finished: Bool) in
                self.draggingView?.removeFromSuperview()
                
                // Reload the rows that were affected just to be safe.
                var visibleRows: [IndexPath] = self.indexPathsForVisibleRows ?? []
                if let indexPath: IndexPath = indexPath,
                   !visibleRows.contains(indexPath) {
                    visibleRows.append(indexPath)
                }
                if let currentLocationIndexPath: IndexPath = self.currentLocationIndexPath,
                   !visibleRows.contains(currentLocationIndexPath) {
                    visibleRows.append(currentLocationIndexPath)
                }
                if !visibleRows.isEmpty {
                    self.reloadRows(at: visibleRows, with: .none)
                }
                
                self.currentLocationIndexPath = nil
                self.draggingView = nil
                
                self.hapticFeedbackSelectionChanged()
                self.hapticFeedbackFinalize()
            })
        default:
            break
        }
    }
    
    fileprivate func updateCurrentLocation(_ gesture: UILongPressGestureRecognizer) {
        let location: CGPoint = gesture.location(in: self)
        guard var indexPath: IndexPath = indexPathForRow(at: location) else { return }
        
        if let iIndexPath: IndexPath = initialIndexPath,
           let ip: IndexPath = delegate?.tableView?(self, targetIndexPathForMoveFromRowAt: iIndexPath, toProposedIndexPath: indexPath) {
            indexPath = ip
        }
        
        guard let clIndexPath: IndexPath = currentLocationIndexPath else { return }
        let oldHeight: CGFloat = rectForRow(at: clIndexPath).size.height
        let newHeight: CGFloat = rectForRow(at: indexPath).size.height
        
        switch gesture.state {
        case .changed:
            if let cell: UITableViewCell = cellForRow(at: clIndexPath) {
                cell.setSelected(false, animated: false)
                cell.setHighlighted(false, animated: false)
                cell.isHidden = true
            }
        default:
            break
        }
        
        guard indexPath != clIndexPath,
              gesture.location(in: cellForRow(at: indexPath)).y > (newHeight - oldHeight),
              canMoveRowAt(indexPath: indexPath) else { return }
        
        beginUpdates()
        moveRow(at: clIndexPath, to: indexPath)
        dataSource?.tableView?(self, moveRowAt: clIndexPath, to: indexPath)
        currentLocationIndexPath = indexPath
        endUpdates()
        
        hapticFeedbackSelectionChanged()
    }
    
    @objc internal func _scrollTableWithCell(_ sender: CADisplayLink) {
        guard let gesture: UILongPressGestureRecognizer = longPressGestureRecognizer else { return }
        
        let location: CGPoint = gesture.location(in: self)
        guard !(location.y.isNaN || location.x.isNaN) else { return } // Explicitly check for out-of-bound touch.
        
        let yOffset: Double = Double(contentOffset.y) + scrollRate * 10.0
        var newOffset: CGPoint = CGPoint(x: contentOffset.x, y: CGFloat(yOffset))
        
        let inset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            inset = adjustedContentInset
        } else {
            inset = contentInset
        }
        
        if newOffset.y < -inset.top {
            newOffset.y = -inset.top
        } else if (contentSize.height + inset.bottom) < frame.size.height {
            newOffset = contentOffset
        } else if newOffset.y > ((contentSize.height + inset.bottom) - frame.size.height) {
            newOffset.y = (contentSize.height + inset.bottom) - frame.size.height
        }
        
        contentOffset = newOffset
        
        if let draggingView: UIView = draggingView {
            draggingView.center = CGPoint(x: center.x, y: newYCenter(for: draggingView, with: location))
        }
        
        updateCurrentLocation(gesture)
    }
    
    fileprivate func newYCenter(for draggingView: UIView, with location: CGPoint) -> CGFloat {
        let cellCenter: CGFloat = draggingView.frame.height / 2
        let bottomBound: CGFloat = contentSize.height - cellCenter
        if location.y < cellCenter {
            return cellCenter
        } else if location.y > bottomBound {
            return bottomBound
        }
        return location.y
    }
    
}

extension LPRTableView {
    
    fileprivate func hapticFeedbackSetup() {
        guard #available(iOS 10.0, *) else { return }
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        self.feedbackGenerator = feedbackGenerator
    }
    
    fileprivate func hapticFeedbackSelectionChanged() {
        guard #available(iOS 10.0, *),
              let feedbackGenerator = self.feedbackGenerator as? UISelectionFeedbackGenerator else { return }
        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
    }
    
    fileprivate func hapticFeedbackFinalize() {
        guard #available(iOS 10.0, *) else { return }
        self.feedbackGenerator = nil
    }
    
}

open class LPRTableViewController: UITableViewController, LPRTableViewDelegate {
    
    /// Returns the long press to reorder table view managed by the controller object.
    open var lprTableView: LPRTableView { return tableView as! LPRTableView }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    public override init(style: UITableView.Style) {
        super.init(style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        tableView = LPRTableView()
        tableView.dataSource = self
        tableView.delegate = self
        registerClasses()
        lprTableView.longPressReorderDelegate = self
    }
    
    /// Override this method to register custom UITableViewCell subclass(es). DO NOT call `super` within this method.
    open func registerClasses() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    /// Asks the delegate whether a given row can be moved to another location in the table view based on the gesture location.
    ///
    /// The default is `true`. The default implementation of this method is empty—no need to call `super`.
    open func tableView(_ tableView: UITableView, shouldMoveRowAtIndexPath indexPath: IndexPath, forDraggingGesture gesture: UILongPressGestureRecognizer) -> Bool {
        return true
    }
    
    /// Provides the delegate a chance to modify the cell visually before dragging occurs.
    ///
    /// Defaults to using the cell as-is if not implemented. The default implementation of this method is empty—no need to call `super`.
    open func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, at indexPath: IndexPath) -> UITableViewCell {
        // Empty implementation, just to simplify overriding (and to show up in code completion).
        return cell
    }
    
    /// Called within an animation block when the dragging view is about to show.
    ///
    /// The default implementation of this method is empty—no need to call `super`.
    open func tableView(_ tableView: UITableView, showDraggingView view: UIView, at indexPath: IndexPath) {
        // Empty implementation, just to simplify overriding (and to show up in code completion).
    }
    
    /// Called within an animation block when the dragging view is about to hide.
    ///
    /// The default implementation of this method is empty—no need to call `super`.
    open func tableView(_ tableView: UITableView, hideDraggingView view: UIView, at indexPath: IndexPath) {
        // Empty implementation, just to simplify overriding (and to show up in code completion).
    }
    
    /// Called when the dragging gesture's vertical location changes.
    ///
    /// The default implementation of this method is empty—no need to call `super`.
    open func tableView(_ tableView: UITableView, draggingGestureChanged gesture: UILongPressGestureRecognizer) {
        // Empty implementation, just to simplify overriding (and to show up in code completion).
    }
    
}
