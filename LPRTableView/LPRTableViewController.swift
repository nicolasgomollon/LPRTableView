//
//  LPRTableViewController.swift
//  LPRTableView
//
//  Created by Yuki Nagai on 10/12/15.
//  Copyright © 2015 Nicolas Gomollon. All rights reserved.
//

import UIKit

public class LPRTableViewController: UITableViewController {
    /// Returns the long press to reorder table view managed by the controller object.
    public var longPressReorderTableView: LPRTableView {
        return tableView as! LPRTableView
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    public override init(style: UITableViewStyle) {
        super.init(style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    private func initialize() {
        if !(tableView is LPRTableView) {
            // You should specify LPRTableView class in LPRTableViewController to load from nib.
            tableView = LPRTableView()
        }
        tableView.dataSource = self
        tableView.delegate = self
        longPressReorderTableView.longPressReorderDelegate = self
    }
}

extension LPRTableViewController: LPRTableViewDelegate {
    public func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cell
    }
    public func tableView(tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
    }
    public func tableView(tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
    }
    public func tableView(tableView: UITableView, shouldMoveRowAtIndexPath: NSIndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
}
