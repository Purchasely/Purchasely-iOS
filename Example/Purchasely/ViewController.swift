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

		NotificationCenter.default.addObserver(self, selector: #selector(reloadContent(_:)), name: .ply_purchasedSubscription, object: nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// The SDK can now pop screens over
		Purchasely.isReadyToPurchase(true)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}


extension ViewController {

	@IBAction func mySubscriptions(_ sender: Any) {
        if let ctrl = Purchasely.subscriptionsController() {
            present(ctrl, animated: true, completion: nil)
        }
	}

	@IBAction func purchase(_ sender: Any) {

        if let ctrl = Purchasely.presentationController(with: "CAROUSEL") {
            present(ctrl, animated: true, completion: nil)
        }
	}
    
    @IBAction func purchaseAsync(_ sender: Any) {

        Purchasely.fetchPresentation(with:"CAROUSEL", fetchCompletion: { [weak self] presentation, error in
            guard let `self` = self else { return }
            if let ctrl = presentation?.controller {
                self.present(ctrl, animated: true, completion: nil)
            }
        }, completion: nil)
    }

	@objc func reloadContent(_ notification: Notification) {
		// Reload content when purchased
	}
}

