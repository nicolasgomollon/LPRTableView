//
//  LPRTableViewDelegate.swift
//  LPRTableView
//
//  Created by Yuki Nagai on 10/12/15.
//  Copyright © 2015 Nicolas Gomollon. All rights reserved.
//

import Foundation

public protocol LPRTableViewDelegate: NSObjectProtocol {
    func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell
    func tableView(tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)
    func tableView(tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)
}

extension LPRTableViewDelegate {
    public func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cell
    }
    
    public func tableView(tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
    }
    
    public func tableView(tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
    }
}
