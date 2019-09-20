//
//  MLFEventCollector.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

class MLFPredictionCollector {
	private let info: [String: String]
	private let extractor: MLFModelDataExtractor
	private let persistence: MLFPersistence
	private let network: MLFNetwork
	private let queue: DispatchQueue
	private let log: MLFLogger
	
	init(
		info: [String: String],
		extractor: MLFModelDataExtractor,
		persistence: MLFPersistence,
		network: MLFNetwork,
		queue: DispatchQueue,
		log: MLFLogger
	) {
		self.info = info
		self.extractor = extractor
		self.persistence = persistence
		self.network = network
		self.queue = queue
		self.log = log
	}
	
	func addModelInformation(info: MLFModelInfo) {
		do {
			let file = try self.persistence.persist(info)
		} catch {
			self.log.i("Failed to save app info to disk. \(error)")
		}
	}
	
	func collect(
		for model: MLFModelId,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		options: MLPredictionOptions? = nil
	) {
		queue.async {
			do {
				let results = self.extractor.convert(input: input, output: output)
				let prediction = MLFPrediction(
					modelId: model,
					input: results.input,
					output: results.output
				)
				let file = try self.persistence.persist(prediction)
			} catch {
				self.log.i("Failed to save prediction to disk. \(error)")
			}
		}
	}
}
