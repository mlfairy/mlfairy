//
//  MLFEventCollector.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Promises

class MLFPredictionCollector {
	private let extractor: MLFModelDataExtractor
	private let upload: MLFUploadTask
	private let queue: DispatchQueue
	
	init(
		extractor: MLFModelDataExtractor,
		upload: MLFUploadTask,
		queue: DispatchQueue
	) {
		self.extractor = extractor
		self.upload = upload
		self.queue = queue
	}
	
	@discardableResult
	func collect(
		for model: MLFModelId,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		options: MLPredictionOptions? = nil
	) -> Promise<MLFPrediction> {
		return Promise(on: self.queue) { () -> MLFPrediction in
			let results = self.extractor.convert(input: input, output: output)
			let prediction = MLFPrediction(
				modelId: model,
				input: results.input,
				output: results.output
			)
			return prediction
		}.then(on: self.queue) { prediction in
			self.upload.queue(prediction)
		}
	}
}
