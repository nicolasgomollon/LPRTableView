//
//  DetailViewController.swift
//  ReorderTest
//
//  Created by Nicolas Gomollon on 6/17/14.
//  Copyright (c) 2014 Techno-Magic. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
	
	@IBOutlet var detailDescriptionLabel: UILabel?

	var detailItem: AnyObject? {
		didSet {
		    // Update the view.
		    configureView()
		}
	}
	
	func configureView() {
		// Update the user interface for the detail item.
		if let detail: AnyObject = detailItem {
		    if let label = detailDescriptionLabel {
		        label.text = detail.description
		    }
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		configureView()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
}

