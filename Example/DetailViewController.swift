//
//  DetailViewController.swift
//  LPRTableView
//
//  Created by Yuki Nagai on 10/13/15.
//  Copyright © 2015 Nicolas Gomollon. All rights reserved.
//

import UIKit

final class DetailViewController: UIViewController {

    // Can be nil when detailItem is updated by prepareForSegue
    @IBOutlet weak var label: UILabel?
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureView() {
        // Update the user interface for the detail item.
        guard let detailItem = detailItem else {
            return
        }
        label?.text = detailItem.description
    }
}
