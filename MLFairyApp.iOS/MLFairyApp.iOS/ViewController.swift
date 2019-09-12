//
//  ViewController.swift
//  MLFairyApp.iOS
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import UIKit
import MLFairy
import Promises

class ViewController: UIViewController {
	private let HEALTH_MODEL_TOKEN = "MLFcfcEL6JiOn5jMEKDsy6n"
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var outputLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	@IBAction func takePhoto(_ sender: Any) {
		
	}
	
	@IBAction func selectPhoto(_ sender: Any) {
		
	}
	
	
	@IBAction func downloadLatest(_ sender: Any) {
		self.outputLabel.text = "Downloading model from MLFairy..."
		MLFairy.getCoreMLModel(HEALTH_MODEL_TOKEN) { model, error in
			guard error == nil else {
				self.outputLabel.text = "Failed to download CoreML model"
				print("Failed to get CoreML model \(String(describing: error)).")
				return
			}
			
			guard let _ = model else {
				self.outputLabel.text = "Failed to assign CoreML model"
				print("Failed to get CoreML model.")
				return
			}
			
			self.outputLabel.text = "Model successfully downloaded"
		}
	}
	
	private func refresh(token: String) {
		
	}
}

