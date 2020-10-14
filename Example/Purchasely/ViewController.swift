//
//  ViewController.swift
//  Purchasely
//
//  Created by jfgrang on 12/27/2019.
//  Copyright (c) 2019 jfgrang. All rights reserved.
//

import UIKit
import Purchasely

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		// The SDK can now pop screens over
		Purchasely.isReadyToPurchase(true)

		NotificationCenter.default.addObserver(self, selector: #selector(reloadContent(_:)), name: .ply_purchasedSubscription, object: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}


extension ViewController {

	@IBAction func purchase(_ sender: Any) {

		Purchasely.productController(for: "PURCHASELY_PLUS", success: { [weak self](controller) in
			self?.present(controller, animated: true, completion: nil)
			}, failure: { _ in
				// Replace by our own page
		})

	}

	@objc func reloadContent(_ notification: Notification) {
		// Reload content when purchased
	}
}

