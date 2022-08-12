//
//  MasterViewController.swift
//  ReorderTest
//
//  Created by Nicolas Gomollon on 6/17/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit

class MasterViewController: LPRTableViewController {
    
    var objects: Array<Date> = .init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func insertNewObject(_ sender: AnyObject) {
        objects.insert(Date(), at: 0)
        let indexPath: IndexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object: Date = objects[indexPath.row]
        cell.textLabel?.text = object.description
        
        //
        // Reset any possible modifications made in `tableView:draggingCell:atIndexPath:`
        // to avoid reusing the modified cell.
        //
//      cell.backgroundColor = .white
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object: Date = objects[indexPath.row]
        let detailViewController: DetailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        detailViewController.detailItem = object as AnyObject?
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
            let indexPath: IndexPath = tableView.indexPathForSelectedRow else { return }
        let object: Date = objects[indexPath.row]
        (segue.destination as! DetailViewController).detailItem = object as AnyObject?
    }
    
    // MARK: - Long Press Reorder
    
    //
    // Important: Update your data source after the user reorders a cell.
    //
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        objects.insert(objects.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
    
    //
    // Optional: Modify the cell (visually) before dragging occurs.
    //
    //    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:`
    //          to avoid accidentally reusing the modifications.
    //
    override func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, at indexPath: IndexPath) -> UITableViewCell {
//      cell.backgroundColor = UIColor(red: 165.0/255.0, green: 228.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        return cell
    }
    
    //
    // Optional: Called within an animation block when the dragging view is about to show.
    //
    override func tableView(_ tableView: UITableView, showDraggingView view: UIView, at indexPath: IndexPath) {
        print("The dragged cell is about to be animated!")
    }
    
    //
    // Optional: Called within an animation block when the dragging view is about to hide.
    //
    override func tableView(_ tableView: UITableView, hideDraggingView view: UIView, at indexPath: IndexPath) {
        print("The dragged cell is about to be dropped.")
    }
    
}
