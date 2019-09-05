//
//  MLFDataModels.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

struct MLFErrorResponse: Codable {
	let message: String
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