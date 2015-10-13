//
//  MasterViewController.swift
//  LPRTableView
//
//  Created by Nicolas Gomollon on 6/17/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit
import LPRTableView

private let cellIdentifier = "Cell"

final class MasterViewController: LPRTableViewController {
    
    private var objects = [NSDate]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(sender: UIBarButtonItem) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }


    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel?.text = object.description
        
        // Reset any possible modifications made in `tableView:draggingCell:atIndexPath:` to avoid reusing the modified cell.

        return cell
    }
    

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            objects.removeAtIndex(indexPath.row)
        default:
            break
        }
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "show":
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                guard let destinationViewController = segue.destinationViewController as? DetailViewController else {
                    return
                }
                destinationViewController.detailItem = object
            }
        default:
            break
        }
    }
    
    // MARK: - Long Press Reorder
    
    // Important: Update your data source after the user reorders a cell.
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        objects.insert(objects.removeAtIndex(sourceIndexPath.row), atIndex: destinationIndexPath.row)
    }
    
    /*
    Optional: Modify the cell (visually) before dragging occurs.
    
    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:` to avoid accidentally reusing the modifications.
    */
    override func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cell
    }
    
    /*
    Optional: Called within an animation block when the dragging view is about to show.
    */
    override func tableView(tableView: UITableView, willAppearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
        print("The dragged cell is about to be animated!")
    }
    
    /*
    Optional: Called within an animation block when the dragging view is about to hide.
    */
    override func tableView(tableView: UITableView, willDisappearDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
        print("The dragged cell is about to be dropped.")
    }
    
    /*
    Optional: Return false for invalid region on cell.
    */
    override func tableView(tableView: UITableView, shouldMoveRowAtIndexPath: NSIndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        let locationInView = gestureRecognizer.locationInView(tableView)
        guard let indexPath = tableView.indexPathForRowAtPoint(locationInView), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return false
        }
        let locationInCell = gestureRecognizer.locationInView(cell)
        return locationInCell.x <= (cell.frame.width / 2)
    }
}
