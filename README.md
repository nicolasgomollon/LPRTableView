# LPRTableView

LPRTableView (LPR is short for LongPressReorderTableView) is a drop-in replacement for UITableView and UITableViewController that supports reordering by simply long-pressing on a cell. LPRTableView is written completely in Swift (adapted from Objective-C, original code by: [bvogelzang/BVReorderTableView](https://github.com/bvogelzang/BVReorderTableView)).

<img alt="Sample Screenshot" width="320" height="568" src="http://f.cl.ly/items/0l0L3X0a2Y3B3J390m3J/SampleScreenshot.png" />


## Usage

Simply replace the `UITableView` of your choice with `LPRTableView`, or replace `UITableViewController` with `LPRTableViewController`. _That’s it!_

It’s **important** that you update your data source after the user reorders a cell:

```swift
override func tableView(tableView: UITableView!, moveRowAtIndexPath sourceIndexPath: NSIndexPath!, toIndexPath destinationIndexPath: NSIndexPath!) {
	let source = objects[sourceIndexPath.row]
	let destination = objects[destinationIndexPath.row]
	objects[sourceIndexPath.row] = destination
	objects[destinationIndexPath.row] = source
}
```

Long-press reordering can be disabled by setting a `Bool` to `lprTableView.longPressReorderEnabled`.

There are also a few _optional_ delegate methods you may implement after setting `lprTableView.longPressReorderDelegate`:

```swift
// Provides a chance to modify the cell (visually) before dragging occurs.
//    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:`
//          to avoid accidentally reusing the modifications.
func tableView(tableView: UITableView!, draggingCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	cell.backgroundColor = UIColor.greenColor()
	return cell
}

// Called within an animation block when the dragging view is about to show.
func tableView(tableView: UITableView!, showDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)

// Called within an animation block when the dragging view is about to hide.
func tableView(tableView: UITableView!, hideDraggingView view: UIView, atIndexPath indexPath: NSIndexPath)
```

See the ReorderTest demo project included in this repository for a working example.


## Requirements

Since LPRTableView is written in Swift, it requires Xcode 6 or above and works on iOS 7 and above.


## License

LPRTableView is released under the MIT License.
