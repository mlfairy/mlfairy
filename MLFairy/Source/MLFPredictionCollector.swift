//
//  MLFEventCollector.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFPredictionCollector {
	private let info: [String: String]
	private let persistence: MLFPersistence
	private let network: MLFNetwork
	private let log: MLFLogger
	
	init(
		info: [String: String],
		persistence: MLFPersistence,
		network: MLFNetwork,
		log: MLFLogger
	) {
		self.info = info
		self.persistence = persistence
		self.network = network
		self.log = log
	}
	
	func addModelInformation(info: [String: String], for model: MLFModelId) {
		
	}
	
	func collect(data: (input: [String: Any], output: [String: Any]), for identifier: MLFModelId) {
		
	}
}
