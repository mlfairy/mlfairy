//
//  ViewController.swift
//  MLFairyApp.iOS
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import UIKit
import MLFairy

class ViewController: UIViewController {
	private let HEALTH_MODEL_TOKEN = "MLFcfcEL6JiOn5jMEKDsy6n"
	private let HEALTH_MODEL_TOKEN_BROKEN = "TUwZTZhZjAtOTIzMS0xMWU5LWEwODItZGQwNWRmMTdjYzFjLzRhYjQ0NDUwLWE3ZTgtMTFlOS04NzNjLTc1MmE5YTZmOWI5Yg=="
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		var button = UIButton(type: .roundedRect)
		button.frame = CGRect(x: 50, y: 50, width: 100, height: 30)
		button.setTitle("good", for: [])
		button.addTarget(self, action: #selector(self.good(_:)), for: .touchUpInside)
		view.addSubview(button)
		
		button = UIButton(type: .roundedRect)
		button.frame = CGRect(x: 50, y: 100, width: 100, height: 30)
		button.setTitle("broken", for: [])
		button.addTarget(self, action: #selector(self.broken(_:)), for: .touchUpInside)
		view.addSubview(button)
	}
	
	@IBAction func broken(_ sender: AnyObject) {
		self.refresh(token: HEALTH_MODEL_TOKEN_BROKEN)
	}
	
	@IBAction func good(_ sender: AnyObject) {
		self.refresh(token: HEALTH_MODEL_TOKEN)
	}
	
	private func refresh(token: String) {
		MLFairy.getCoreMLModel(token) { model, error in
			guard error == nil else {
				print("Failed to get CoreML model \(String(describing: error)).")
				return
			}

			guard let _ = model else {
				print("Failed to get CoreML model.")
				return
			}

			print("Model Downloaded")
//			ml.model = model
		}
	}
}

