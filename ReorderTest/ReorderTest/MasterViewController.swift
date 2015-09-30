//
//  MasterViewController.swift
//  ReorderTest
//
//  Created by Nicolas Gomollon on 6/17/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit

class MasterViewController: LPRTableViewController {
	
	var objects = Array<NSDate>()
	
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
		navigationItem.leftBarButtonItem = self.editButtonItem()
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func insertNewObject(sender: AnyObject) {
		objects.insert(NSDate(), atIndex: 0)
		let indexPath = NSIndexPath(forRow: 0, inSection: 0)
		tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
	}
	
	// MARK: - Table View
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return objects.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
		
		let object = objects[indexPath.row]
		cell.textLabel?.text = object.description
		
		//
		// Reset any possible modifications made in `tableView:draggingCell:atIndexPath:`
		// to avoid reusing the modified cell.
		//
//		cell.backgroundColor = .whiteColor()
		
		return cell
	}
	
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}
	
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			objects.removeAtIndex(indexPath.row)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		} else if editingStyle == .Insert {
			// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let object = objects[indexPath.row]
		let detailViewController = storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
		detailViewController.detailItem = object
		navigationController?.pushViewController(detailViewController, animated: true)
	}
	
	// MARK: - Segues
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
			if let indexPath = tableView.indexPathForSelectedRow {
				let object = objects[indexPath.row]
				(segue.destinationViewController as! DetailViewController).detailItem = object
			}
		}
	}
	
	// MARK: - Long Press Reorder
	
	//
	// Important: Update your data source after the user reorders a cell.
	//
	override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		objects.insert(objects.removeAtIndex(sourceIndexPath.row), atIndex: destinationIndexPath.row)
	}
	
	//
	// Optional: Modify the cell (visually) before dragging occurs.
	//
	//    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:`
	//          to avoid accidentally reusing the modifications.
	//
	override func tableView(tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//		cell.backgroundColor = UIColor(red: 165.0/255.0, green: 228.0/255.0, blue: 255.0/255.0, alpha: 1.0)
		return cell
	}
	
	//
	// Optional: Called within an animation block when the dragging view is about to show.
	//
	override func tableView(tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
		print("The dragged cell is about to be animated!")
	}
	
	//
	// Optional: Called within an animation block when the dragging view is about to hide.
	//
	override func tableView(tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath) {
		print("The dragged cell is about to be dropped.")
	}
	
}
