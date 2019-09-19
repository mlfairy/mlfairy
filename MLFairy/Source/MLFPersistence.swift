//
//  MLFPersistence.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CommonCrypto

typealias OnDiskDownloadMetadata = (url: URL?, metadata: MLFDownloadMetadata?)

protocol MLFPersistence {
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws
	func findModel(for token: String) throws -> OnDiskDownloadMetadata
	func modelFileFor(model: MLFDownloadMetadata) throws -> URL?
	func deleteFile(at url: URL)
	func exists(file: URL) throws -> Bool
	func md5File(url: URL, bufferSize: Int) throws -> [UInt8]
}

extension MLFPersistence {
	func md5File(url: URL, bufferSize: Int = 1048576) throws -> [UInt8] { return try self.md5File(url: url, bufferSize: bufferSize)}
}

class MLFDefaultPersistence: MLFPersistence {
	private let fileManager: FileManager
	private let sdkDirectoryPath: URL
	private let modelDirectoryUrl: URL
	private let log: MLFLogger
	
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	
	private var metadataMap: [String: MLFDownloadMetadata] = [:]
	
	init(fileManager: FileManager, root: URL, log: MLFLogger) {
		self.fileManager = fileManager
		self.log = log
		self.sdkDirectoryPath = root
			.appendingPathComponent("com.mlfairy", isDirectory: true)
		self.modelDirectoryUrl = self.sdkDirectoryPath
			.appendingPathComponent("models", isDirectory: true)
		
		self.initLocalFolders()
	}
	
	func exists(file: URL) -> Bool {
		return self.fileManager.fileExists(atPath: file.path)
	}
	
	func size(url: URL) throws -> Int? {
		do {
			let resources = try url.resourceValues(forKeys: [.fileSizeKey])
			return resources.fileSize
		} catch {
			self.log.d("Failed to get size for directory \(url): \(error)")
			throw error
		}
	}
	
	func findModel(for token: String) throws -> OnDiskDownloadMetadata {
		guard let metadata = try self.findDownloadMetadata(for: token) else {
			return (nil, nil)
		}
		
		return (try self.modelFileFor(model: metadata), metadata)
	}
	
	private func findDownloadMetadata(for token: String) throws -> MLFDownloadMetadata? {
		if let metadata = self.metadataMap[token] {
			return metadata
		}
		
		guard let path = try self.directoryFor(token: token) else {
			return nil
		}
		
		let metadataUrl = path.appendingPathComponent(".metadata")
		if (!self.exists(file: metadataUrl)) {
			return nil
		}
		
		do {
			let data = try Data(contentsOf: metadataUrl)
			let metadata = try decoder.decode(MLFDownloadMetadata.self, from: data)
			self.metadataMap[token] = metadata
			
			return metadata
		} catch {
			self.log.d("Failed to read metadata for token \(token): \(error)")
			return nil
		}
	}
	
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws {
		guard let path = try self.directoryFor(token: token) else {
			return
		}
		
		let metadataUrl = path.appendingPathComponent(".metadata")
		do {
			try self.write(metadata, to: metadataUrl)
			self.metadataMap[token] = metadata
		} catch {
			self.log.d("Failed to write metadata for token \(token): \(error)")
			throw error
		}
	}
	
	private func write<T>(_ input: T, to url: URL) throws where T: Encodable{
		var options: Data.WritingOptions = [.atomic]
		#if os(iOS)
		options.insert(.completeFileProtectionUnlessOpen)
		#endif
		
		let data = try self.encoder.encode(input)
		try data.write(to: url, options: options)
	}
	
	func directoryFor(token: String) throws -> URL? {
		do {
			let modelDirectory = self.modelDirectoryUrl
				.appendingPathComponent(token, isDirectory: true)
			try self.fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
			
			return modelDirectory
		} catch {
			self.log.d("Failed to create model directory for token \(token): \(error)")
			throw error
		}
	}
	
	func modelFileFor(model: MLFDownloadMetadata) throws -> URL? {
		guard let activeVersion = model.activeVersion else { return nil }
		
		if let path = try self.directoryFor(token: model.token) {
			return path.appendingPathComponent(activeVersion)
		}
		
		return nil
	}
	
	func md5File(
		url: URL,
		bufferSize: Int = 1048576
	) throws -> [UInt8] {
		// Open file for reading:
		let file = try FileHandle(forReadingFrom: url)
		defer {
			file.closeFile()
		}
		
		// Create and initialize MD5 context:
		var context = CC_MD5_CTX()
		CC_MD5_Init(&context)
		
		// Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
		while autoreleasepool(invoking: {
			let data = file.readData(ofLength: bufferSize)
			if data.count > 0 {
				data.withUnsafeBytes {
					_ = CC_MD5_Update(&context, $0.baseAddress, numericCast(data.count))
				}
				return true // Continue
			} else {
				return false // End of file
			}
		}) { }
		
		// Compute the MD5 digest:
		var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
		_ = CC_MD5_Final(&digest, &context)
		
		return digest
	}
	
	func deleteFile(at url: URL) {
		try? self.fileManager.removeItem(at: url)
	}
	
	private func initLocalFolders() {
		do {
			try self.fileManager.createDirectory(at: self.sdkDirectoryPath, withIntermediateDirectories: true)
			try self.fileManager.createDirectory(at: modelDirectoryUrl, withIntermediateDirectories: true)
			
			var sdkDirectoryPath = self.sdkDirectoryPath
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = true
			try sdkDirectoryPath.setResourceValues(resourceValues)
		} catch {
			self.log.e("Failed to initialize local directories: \(error)")
		}
	}
}
