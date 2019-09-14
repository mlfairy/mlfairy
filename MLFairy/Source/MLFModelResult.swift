//
//  MLFModelResult.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

public struct MLFModelResult {
	public let result: Result<MLModel?, Error>
	public let compiledModel: MLModel?
	public let compiledModelUrl: URL?
	public let downloadedModelUrl: URL?
	public let mlFairyModel: MLFModel?
	
	/// Returns the associated value of the result if it is a success, `nil` otherwise.
	public var model: MLModel?? { return result.success }
	
	/// Returns the associated error value if the result if it is a failure, `nil` otherwise.
	public var error: Error? { return result.failure }
	
	init(
		result: Result<MLModel?, Error>,
		compiledModel: MLModel?,
		compiledModelUrl: URL?,
		downloadedModelUrl: URL?,
		mlFairyModel: MLFModel?
	) {
		self.result = result
		self.compiledModel = compiledModel
		self.compiledModelUrl = compiledModelUrl
		self.downloadedModelUrl = downloadedModelUrl
		self.mlFairyModel = mlFairyModel
	}
}

extension Result {
	/// Returns the associated value if the result is a success, `nil` otherwise.
	var success: Success? {
		guard case let .success(value) = self else { return nil }
		return value
	}
	
	/// Returns the associated error value if the result is a failure, `nil` otherwise.
	var failure: Failure? {
		guard case let .failure(error) = self else { return nil }
		return error
	}

	/// Initializes a `Result` from value or error. Returns `.failure` if the error is non-nil, `.success` otherwise.
	///
	/// - Parameters:
	///   - value: A value.
	///   - error: An `Error`.
	init(value: Success, error: Failure?) {
		if let error = error {
			self = .failure(error)
		} else {
			self = .success(value)
		}
	}
}
