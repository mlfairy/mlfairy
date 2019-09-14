//
//  ViewController.swift
//  MLFairyApp.iOS
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import UIKit
import Vision

import MLFairy

class ViewController: UIViewController {
	private let MLFAIRY_TOKEN = "MLFcfcEL6JiOnUzXdaHUxrl"
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var outputLabel: UILabel!
	@IBOutlet weak var cameraButton: UIButton!
	
	private let model = MobileNetV2Int8LUT()
	
	lazy var classificationRequest: VNCoreMLRequest = {
		do {
			let model = try VNCoreMLModel(for: self.model.model)
			
			let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
				self?.processClassifications(for: request, error: error)
			})
			request.imageCropAndScaleOption = .centerCrop
			return request
		} catch {
			fatalError("Failed to load Vision ML model: \(error)")
		}
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.outputLabel.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
		cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
		
		model.model = MLFairy.wrapMpdel(model.model, token: MLFAIRY_TOKEN)
	}
	
	@IBAction func takePhoto(_ sender: Any) {
		presentPhotoPicker(sourceType: .camera)
	}
	
	@IBAction func selectPhoto(_ sender: Any) {
		presentPhotoPicker(sourceType: .photoLibrary)
	}
	
	@IBAction func downloadLatest(_ sender: Any) {
		self.outputLabel.text = "Downloading model from MLFairy..."
		MLFairy.getCoreMLModel(MLFAIRY_TOKEN) { result in
			switch (result.result) {
				case .success(let model):
					guard let model = model else {
						self.outputLabel.text = "Failed to assign CoreML model"
						print("Failed to get CoreML model.")
						return
					}
					
					self.outputLabel.text = "Model successfully downloaded"
					self.model.model = model
				case .failure(let error):
					self.outputLabel.text = "Failed to download CoreML model"
					print("Failed to get CoreML model \(String(describing: error)).")
			}
		}
	}
	
	func classify(image: UIImage) {
		guard let ciImage = CIImage(image: image) else {
			print("Unable to create CIImage")
			return
		}
		
		let orientation = CGImagePropertyOrientation(image.imageOrientation)
		
		DispatchQueue.global(qos: .userInitiated).async {
			let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
			do {
				try handler.perform([self.classificationRequest])
			} catch {
				print("Failed to perform classification: \(error)")
				self.outputLabel.text = "Failed to perform classification: \(error)"
			}
		}
	}
	
	func processClassifications(for request: VNRequest, error: Error?) {
		DispatchQueue.main.async {
			guard let results = request.results else {
				self.outputLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
				return
			}
			
			let classifications = results as! [VNClassificationObservation]
			
			if classifications.isEmpty {
				self.outputLabel.text = "Nothing recognized."
			} else {
				// Display top classifications ranked by confidence in the UI.
				let topClassifications = classifications.prefix(2)
				let descriptions = topClassifications.map { classification in
					// Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
					return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
				}
				self.outputLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
			}
		}
	}
	
	private func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
		switch sourceType {
		case .camera: self.outputLabel.text = "Take a photo"
		case .photoLibrary: self.outputLabel.text = "Select a photo"
		default: self.outputLabel.text = ""
		}

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
		
		classify(image: image)
	}
}

extension CGImagePropertyOrientation {
	init(_ orientation: UIImage.Orientation) {
		switch orientation {
		case .upMirrored: self = .upMirrored
		case .down: self = .down
		case .downMirrored: self = .downMirrored
		case .left: self = .left
		case .leftMirrored: self = .leftMirrored
		case .right: self = .right
		case .rightMirrored: self = .rightMirrored
		default: self = .up
		}
	}
}

extension CGImagePropertyOrientation {
	init(_ orientation: UIDeviceOrientation) {
		switch orientation {
		case .portraitUpsideDown: self = .left
		case .landscapeLeft: self = .up
		case .landscapeRight: self = .down
		default: self = .right
		}
	}
}
