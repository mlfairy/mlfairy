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
	@IBOutlet weak var cameraButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
	}
	
	@IBAction func takePhoto(_ sender: Any) {
		presentPhotoPicker(sourceType: .camera)
	}
	
	@IBAction func selectPhoto(_ sender: Any) {
		presentPhotoPicker(sourceType: .photoLibrary)
	}
	
	@IBAction func downloadLatest(_ sender: Any) {
		self.outputLabel.text = "Downloading model from MLFairy..."
		MLFairy.getCoreMLModel(HEALTH_MODEL_TOKEN) { result in
			switch (result.result) {
				case .success(let model):
					guard let _ = model else {
						self.outputLabel.text = "Failed to assign CoreML model"
						print("Failed to get CoreML model.")
						return
					}
					
					self.outputLabel.text = "Model successfully downloaded"
					break
				case .failure(let error):
					self.outputLabel.text = "Failed to download CoreML model"
					print("Failed to get CoreML model \(String(describing: error)).")
					break
			}
		}
	}
	
	private func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
		self.outputLabel.text = ""
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.sourceType = sourceType
		present(picker, animated: true)
	}
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(
		_ picker: UIImagePickerController,
		didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
	) {
		picker.dismiss(animated: true)
		
		let image = info[.originalImage] as! UIImage
		imageView.image = image
	}
}

