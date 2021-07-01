//
//  MLFModelDataExtractor.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import MLFSupport

class MLFModelDataExtractor {
	private let support: MLFTools
	
	init(support: MLFTools) {
		self.support = support
	}
	
	func modelInformation(model: MLModel) -> [String: String] {
		return self.support.describe(model: model)
	}
	
	func convert(
		input: MLFeatureProvider,
		output: MLFeatureProvider
	) -> (input:[String: [String: String]], output: [String: [String: String]]) {
		let inputResult = self.support.encode(input: input)
		let outputResult = self.support.encode(input: output)
		return (input: inputResult, output: outputResult)
	}
}
