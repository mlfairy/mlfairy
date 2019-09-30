//
//  MLFDataModels.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
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

struct MLFPrediction: Codable {
	let type = "prediction"
	let modelId: MLFModelId
	let input: [String: [String: String]]
	let output: [String: [String: String]]
	let appInfo: [String: String]
	let elapsed: Double?
}

struct MLFModelInfo: Codable {
	let type = "modelInfo"
	let modelId: MLFModelId
	let info: [String: String]
}

struct MLFErrorResponse: Codable {
	let message: String
}

struct MLFModelId: Codable {
	public let token: String
	public let downloadId: String?
	
	init(metadata: MLFDownloadMetadata) {
		self.init(token: metadata.token, downloadId: metadata.downloadId)
	}
	
	init(token: String, downloadId: String?) {
		self.token = token
		self.downloadId = downloadId
	}
}

struct MLFDownloadMetadata: Codable {
	let downloadId: String
	let modelId: String
	let organizationId: String
	let token: String
	
	let activeVersion: String?
	let modelFileUrl: String?
	let hash: String?
	let digest: String?
	let algorithm: String?
	let size: Int?
}

struct MLFUploadResponse: Codable {
	let message: String
}

extension MLFDownloadMetadata: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		return "\(downloadId)"
	}
	
	public var debugDescription: String {
		var url = "None"
		if let modelUrl = self.modelFileUrl {
			url = String(modelUrl.prefix(min(modelUrl.count, 20)))
		}
		
		return """
		[Download]: \(downloadId)
		[Model]: \(modelId)
		[Organization]: \(downloadId)
		[Token]: \(token)
		[Active]: \(activeVersion ?? "None")
		[URL]: \(url)
		[algorithm]: \(algorithm ?? "Unknown")
		[digest]: \(digest ?? "Unknown")
		[hash]: \(hash ?? "Unknown")
		[size]: \(size ?? -1)
		"""
	}
}

public enum MLFError: Error {
	case compilationFailed(message: String, reason: Error)
	case checksumError(error: Error)
	case downloadFailed(message: String, reason: Error)
	case failedChecksum
	case networkError(response: String)
	case noDownloadAvailable
}

public enum MLFModelError: Error {
	case notSupported
}
