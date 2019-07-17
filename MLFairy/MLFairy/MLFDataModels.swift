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
}

