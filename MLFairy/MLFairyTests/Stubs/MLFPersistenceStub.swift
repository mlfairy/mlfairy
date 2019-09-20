//
//  MLFPersistenceStub.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
@testable import MLFairy

class MLFPersistenceStub: MLFPersistence {
	var saveCallback: (() throws -> URL)?
	var findModelCallback: (() throws -> OnDiskDownloadMetadata)?
	var modelFileForCallback: (() throws -> URL?)?
	var existsCallback: (() throws -> Bool)?
	var uploadsCallback: (() -> [URL])?
	
	private let fallback: MLFPersistence
	
	init(log: MLFLogger) {
		self.fallback = MLFDefaultPersistence(
			fileManager: FileManager.default,
			root: URL(fileURLWithPath: NSTemporaryDirectory()),
			log: log
		)
	}
	
	@discardableResult
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws -> URL {
		return try saveCallback!()
	}
	
	func uploads() -> [URL] {
		return uploadsCallback!()
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
	
	func persist<T:Encodable>(_ data: T) throws -> URL {
		return try self.fallback.persist(data)
	}
}
