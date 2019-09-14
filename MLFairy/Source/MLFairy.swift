//
//  MLFairy.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

public class MLFairy {
	private static let `default` = MLFairyImpl()

	public static func getCoreMLModel(
		_ modelToken: String,
		queue: DispatchQueue = .main,
		callback: @escaping (MLFModelResult) -> Void
	) {
		MLFairy.default.getCoreMLModel(
			token:modelToken,
			queue: queue,
			callback:callback
		)
	}
	
	public static func wrapMpdel(_ input: MLModel, token modelToken: String) -> MLFModel {
		return MLFairy.default.wrap(input, token: modelToken)
	}
}
