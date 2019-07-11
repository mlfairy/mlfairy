//
//  ViewController.swift
//  MLFairyApp.iOS
//
//  Created by Vijay Sharma on 2019-07-10.
//  Copyright © 2019 MLFairy. All rights reserved.
//

import UIKit
import MLFairy

class ViewController: UIViewController {
	private let HEALTH_MODEL_TOKEN = "MTUwZTZhZjAtOTIzMS0xMWU5LWEwODItZGQwNWRmMTdjYzFjL2QwYTdhZmYwLWExYWYtMTFlOS1hMmNkLWI3N2ViM2M0MzI4OA=="
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let ml = HealthySnacks()
		
		MLFairy.getCoreMLModel(HEALTH_MODEL_TOKEN) { model, error in
			guard error == nil else {
				print("Failed to get CoreML model \(String(describing: error)).")
				return
			}
			
			guard let model = model else {
				print("Failed to get CoreML model.")
				return
			}
			
			ml.model = model
		}
	}
}

