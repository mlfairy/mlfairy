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
	
	func addModelInformation(info: [String: String], for model: MLFModelId) {
		// TODO: Write to disk and send to server?
	}
	
	func collect(
		for model:MLFModelId,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		options: MLPredictionOptions? = nil
	) {
		queue.async {
			let result = self.extractor.convert(input: input, output: output)
			self.collect(data: result, for: model)
		}
	}
	
	func collect(data: (input: [String: Any], output: [String: Any]), for identifier: MLFModelId) {
		
	}
}
