//
//  ViewController.swift
//  MLFairyApp.iOS
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import UIKit
import MLFairy

public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
	let output = items.map { "\($0)" }.joined(separator: separator)
	Swift.print(output, terminator: terminator)
}

class ViewController: UIViewController {
//	private let HEALTH_MODEL_TOKEN = "MTUwZTZhZjAtOTIzMS0xMWU5LWEwODItZGQwNWRmMTdjYzFjL2QwYTdhZmYwLWExYWYtMTFlOS1hMmNkLWI3N2ViM2M0MzI4OA=="
	private let HEALTH_MODEL_TOKEN = "MTUwZTZhZjAtOTIzMS0xMWU5LWEwODItZGQwNWRmMTdjYzFjLzRhYjQ0NDUwLWE3ZTgtMTFlOS04NzNjLTc1MmE5YTZmOWI5Yg=="
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let button = UIButton(type: .roundedRect)
		button.frame = CGRect(x: 50, y: 50, width: 100, height: 30)
		button.setTitle("Refresh", for: [])
		button.addTarget(self, action: #selector(self.download(_:)), for: .touchUpInside)
		view.addSubview(button)
		
		self.refresh()
	}
	
	@IBAction func download(_ sender: AnyObject) {
		self.refresh()
	}
	
	private func refresh() {
		MLFairy.getCoreMLModel(HEALTH_MODEL_TOKEN) { model, error in
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

