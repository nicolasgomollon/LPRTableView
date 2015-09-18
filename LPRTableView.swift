//
//  LPRTableView.swift
//  LPRTableView
//
//  Objective-C code Copyright (c) 2013 Ben Vogelzang. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

/** The delegate of a LPRTableView object can adopt the LPRTableViewDelegate protocol. Optional methods of the protocol allow the delegate to modify a cell visually before dragging occurs, or to be notified when a cell is about to be dragged or about to be dropped. */
@objc
public protocol LPRTableViewDelegate: NSObjectProtocol {
	
	/** Provides the delegate a chance to modify the cell visually before dragging occurs. Defaults to using the cell as-is if not implemented. */
	optional func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell
	
	/** Called within an animation block when the dragging view is about to show. */
	optional func tableView(tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)
	
	/** Called within an animation block when the dragging view is about to hide. */
	optional func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)
	
}

public class LPRTableView: UITableView {
	
	/** The object that acts as the delegate of the receiving table view. */
	public var longPressReorderDelegate: LPRTableViewDelegate!
	
	private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	
	private var initialIndexPath: NSIndexPath?
	
	private var currentLocationIndexPath: NSIndexPath?
	
	private var draggingView: UIView?
	
	private var scrollRate = 0.0
	
	private var scrollDisplayLink: CADisplayLink?
	
	/** A Bool property that indicates whether long press to reorder is enabled. */
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
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "_longPress:")
		addGestureRecognizer(longPressGestureRecognizer)
	}
	
}

extension LPRTableView {
	
	private func canMoveRowAt(indexPath indexPath: NSIndexPath) -> Bool {
		return (dataSource?.respondsToSelector("tableView:canMoveRowAtIndexPath:") == false) || (dataSource?.tableView?(self, canMoveRowAtIndexPath: indexPath) == true)
	}
	
	private func cancelGesture() {
		longPressGestureRecognizer.enabled = false
		longPressGestureRecognizer.enabled = true
	}
	
	internal func _longPress(gesture: UILongPressGestureRecognizer) {
		
		let location = gesture.locationInView(self)
		let indexPath = indexPathForRowAtPoint(location)
		
		let sections = numberOfSections
		var rows = 0
		for i in 0..<sections {
			rows += numberOfRowsInSection(i)
		}
		
		// Get out of here if the long press was not on a valid row or our table is empty
		// or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row.
		if (rows == 0) ||
			((gesture.state == UIGestureRecognizerState.Began) && (indexPath == nil)) ||
			((gesture.state == UIGestureRecognizerState.Ended) && (currentLocationIndexPath == nil)) ||
			((gesture.state == UIGestureRecognizerState.Began) && !canMoveRowAt(indexPath: indexPath!)) {
				cancelGesture()
				return
		}
		
		// Started.
		if gesture.state == .Began {
			if let indexPath = indexPath {
				if var cell = cellForRowAtIndexPath(indexPath) {
					
					cell.setSelected(false, animated: false)
					cell.setHighlighted(false, animated: false)
					
					// Create the view that will be dragged around the screen.
					if (draggingView == nil) {
						if let draggingCell = longPressReorderDelegate?.tableView?(self, draggingCell: cell, atIndexPath: indexPath) {
							cell = draggingCell
						}
						
						// Make an image from the pressed table view cell.
						UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
						cell.layer.renderInContext(UIGraphicsGetCurrentContext()!)
						let cellImage = UIGraphicsGetImageFromCurrentImageContext()
						UIGraphicsEndImageContext()
						
						draggingView = UIImageView(image: cellImage)
						
						if let draggingView = draggingView {
							addSubview(draggingView)
							let rect = rectForRowAtIndexPath(indexPath)
							draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y)
							
							UIView.beginAnimations("LongPressReorder-ShowDraggingView", context: nil)
							longPressReorderDelegate?.tableView?(self, showDraggingView: draggingView, atIndexPath: indexPath)
							UIView.commitAnimations()
							
							// Add drop shadow to image and lower opacity.
							draggingView.layer.masksToBounds = false
							draggingView.layer.shadowColor = UIColor.blackColor().CGColor
							draggingView.layer.shadowOffset = CGSizeZero
							draggingView.layer.shadowRadius = 4.0
							draggingView.layer.shadowOpacity = 0.7
							draggingView.layer.opacity = 0.85
							
							// Zoom image towards user.
							UIView.beginAnimations("LongPressReorder-Zoom", context: nil)
							draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1)
							draggingView.center = CGPointMake(center.x, location.y)
							UIView.commitAnimations()
						}
					}
					
					cell.hidden = true
					currentLocationIndexPath = indexPath
					initialIndexPath = indexPath
					
					// Enable scrolling for cell.
					scrollDisplayLink = CADisplayLink(target: self, selector: "_scrollTableWithCell:")
					scrollDisplayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
				}
			}
		}
		// Dragging.
		else if gesture.state == .Changed {
			
			if let draggingView = draggingView {
				// Update position of the drag view,
				// but don't let it go past the top or the bottom too far.
				if (location.y >= 0.0) && (location.y <= contentSize.height + 50.0) {
					draggingView.center = CGPointMake(center.x, location.y)
				}
			}
			
			var rect = bounds
			// Adjust rect for content inset, as we will use it below for calculating scroll zones.
			rect.size.height -= contentInset.top
			
			updateCurrentLocation(gesture)
			
			// Tell us if we should scroll, and in which direction.
			let scrollZoneHeight = rect.size.height / 6.0
			let bottomScrollBeginning = contentOffset.y + contentInset.top + rect.size.height - scrollZoneHeight
			let topScrollBeginning = contentOffset.y + contentInset.top  + scrollZoneHeight
			
			// We're in the bottom zone.
			if location.y >= bottomScrollBeginning {
				scrollRate = Double(location.y - bottomScrollBeginning) / Double(scrollZoneHeight)
			}
			// We're in the top zone.
			else if location.y <= topScrollBeginning {
				scrollRate = Double(location.y - topScrollBeginning) / Double(scrollZoneHeight)
			}
			else {
				scrollRate = 0.0
			}
		}
		// Dropped.
		else if gesture.state == .Ended {
			
			// Remove scrolling CADisplayLink.
			scrollDisplayLink?.invalidate()
			scrollDisplayLink = nil
			scrollRate = 0.0
			
			// Animate the drag view to the newly hovered cell.
			UIView.animateWithDuration(0.3,
				animations: { [unowned self] in
					if let draggingView = self.draggingView {
						if let currentLocationIndexPath = self.currentLocationIndexPath {
							UIView.beginAnimations("LongPressReorder-HideDraggingView", context: nil)
							self.longPressReorderDelegate?.tableView?(self, hideDraggingView: draggingView, atIndexPath: currentLocationIndexPath)
							UIView.commitAnimations()
							let rect = self.rectForRowAtIndexPath(currentLocationIndexPath)
							draggingView.transform = CGAffineTransformIdentity
							draggingView.frame = CGRectOffset(draggingView.bounds, rect.origin.x, rect.origin.y)
						}
					}
				},
				completion: { [unowned self] (finished: Bool) in
					if let draggingView = self.draggingView {
						draggingView.removeFromSuperview()
					}
					
					// Reload the rows that were affected just to be safe.
					if let visibleRows = self.indexPathsForVisibleRows {
						self.reloadRowsAtIndexPaths(visibleRows, withRowAnimation: .None)
					}
					
					self.currentLocationIndexPath = nil
					self.draggingView = nil
				})
		}
	}
	
	private func updateCurrentLocation(gesture: UILongPressGestureRecognizer) {
		let location = gesture.locationInView(self)
		if var indexPath = indexPathForRowAtPoint(location) {
			
			if let iIndexPath = initialIndexPath {
				if let ip = delegate?.tableView?(self, targetIndexPathForMoveFromRowAtIndexPath: iIndexPath, toProposedIndexPath: indexPath) {
					indexPath = ip
				}
			}
			
			if let clIndexPath = currentLocationIndexPath {
				let oldHeight = rectForRowAtIndexPath(clIndexPath).size.height
				let newHeight = rectForRowAtIndexPath(indexPath).size.height
				
				if ((indexPath != clIndexPath) &&
					(gesture.locationInView(cellForRowAtIndexPath(indexPath)).y > (newHeight - oldHeight))) &&
					canMoveRowAt(indexPath: indexPath) {
						beginUpdates()
						moveRowAtIndexPath(clIndexPath, toIndexPath: indexPath)
						dataSource?.tableView?(self, moveRowAtIndexPath: clIndexPath, toIndexPath: indexPath)
						currentLocationIndexPath = indexPath
						endUpdates()
				}
			}
		}
	}
	
	internal func _scrollTableWithCell(sender: CADisplayLink) {
		if let gesture = longPressGestureRecognizer {
			
			let location = gesture.locationInView(self)
			
		        if !(location.y.isNaN || location.x.isNaN) { //explicitly check for out-of-bound touch
		
		                let yOffset = Double(contentOffset.y) + scrollRate * 10.0
		                var newOffset = CGPointMake(contentOffset.x, CGFloat(yOffset))
		                
		                if newOffset.y < -contentInset.top {
		                    newOffset.y = -contentInset.top
		                } else if (contentSize.height + contentInset.bottom) < frame.size.height {
		                    newOffset = contentOffset
		                } else if newOffset.y > ((contentSize.height + contentInset.bottom) - frame.size.height) {
		                    newOffset.y = (contentSize.height + contentInset.bottom) - frame.size.height
		                }
		                
		                contentOffset = newOffset
		                
		                if let draggingView = draggingView {
		                    if (location.y >= 0) && (location.y <= (contentSize.height + 50.0)) {
		                        draggingView.center = CGPointMake(center.x, location.y)
		                    }
		                }
		                
		                updateCurrentLocation(gesture)
		        }			
		}
	}
	
}

public class LPRTableViewController: UITableViewController, LPRTableViewDelegate {
	
	/** Returns the long press to reorder table view managed by the controller object. */
	public var lprTableView: LPRTableView! { return tableView as! LPRTableView }
	
	public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		initialize()
	}
	
	public override init(style: UITableViewStyle) {
		super.init(style: style)
		initialize()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	private func initialize() {
		tableView = LPRTableView()
		tableView.dataSource = self
		tableView.delegate = self
		registerClasses()
		lprTableView.longPressReorderDelegate = self
	}
	
	/** Override this method to register custom UITableViewCell subclass(es). DO NOT call `super` within this method. */
	public func registerClasses() {
		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	}
	
	/** Provides the delegate a chance to modify the cell visually before dragging occurs. Defaults to using the cell as-is if not implemented. The default implementation of this method is empty—no need to call `super`. */
	public func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		// Empty implementation, just to simplify overriding (and to show up in code completion).
		return cell
	}
	
	/** Called within an animation block when the dragging view is about to show. The default implementation of this method is empty—no need to call `super`. */
	public func tableView(tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
		// Empty implementation, just to simplify overriding (and to show up in code completion).
	}
	
	/** Called within an animation block when the dragging view is about to hide. The default implementation of this method is empty—no need to call `super`. */
	public func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
		// Empty implementation, just to simplify overriding (and to show up in code completion).
	}
	
}
