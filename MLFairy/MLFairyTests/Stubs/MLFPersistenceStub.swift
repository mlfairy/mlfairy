//
//  MLFPersistenceStub.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
@testable import MLFairy

class MLFPersistenceStub: MLFPersistence {
	var saveCallback: (() throws -> ())?
	var findModelCallback: (() throws -> (OnDiskDownloadMetadata))?
	var modelFileForCallback: (() throws -> (URL?))?
	var existsCallback: (() throws -> (Bool))?
	
	private let fallback: MLFPersistence
	
	init(log: MLFLogger) {
		self.fallback = MLFDefaultPersistence(
			fileManager: FileManager.default,
			root: URL(fileURLWithPath: NSTemporaryDirectory()),
			log: log
		)
	}
	
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws {
		try saveCallback!()
	}
	
	func findModel(for token: String) throws -> OnDiskDownloadMetadata {
		return try findModelCallback!()
	}
	
	func modelFileFor(model: MLFDownloadMetadata) throws -> URL? {
		return try modelFileForCallback!()
	}
	
	func deleteFile(at url: URL) {}
	
	func exists(file: URL) throws -> Bool {
		return try existsCallback!()
	}
	
	func md5File(url: URL, bufferSize: Int) throws -> [UInt8] {
		return try self.fallback.md5File(url: url, bufferSize: bufferSize)
	}
}
