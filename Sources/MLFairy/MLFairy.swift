//
//  MLFairy.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

public class MLFairy {
	public struct Options: OptionSet {
		public static let alwaysDownloadLatest = Options(rawValue: 1)
		public static let skipCompilation = Options(rawValue: 2)
		
		public let rawValue: Int
		
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}
	private static let `default` = MLFairyImpl()

	public static func getCoreMLModel(
		_ modelToken: String,
		queue: DispatchQueue = .main,
		callback: @escaping (MLFModelResult) -> Void
	) {
		MLFairy.default.getCoreMLModel(
			token: modelToken,
			options: [],
			queue: queue,
			callback: callback
		)
	}
	
	public static func wrapCoreMLModel(
		_ input: MLModel,
		token modelToken: String
	) -> MLFModel {
		return MLFairy.default.wrap(input, token: modelToken)
	}
	
	public static func collectCoreMLPrediction(
		token: String,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		elapsed: DispatchTimeInterval = .never
	) {
		return MLFairy.default.collect(
			token: token,
			input: input,
			output: output,
			elapsed: elapsed
		)
	}
}
