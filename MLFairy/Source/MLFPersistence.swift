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
	@discardableResult
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws -> URL
	func findModel(for token: String) throws -> OnDiskDownloadMetadata
	func modelFileFor(model: MLFDownloadMetadata) throws -> URL?
	func deleteFile(at url: URL)
	func exists(file: URL) throws -> Bool
	func md5File(url: URL, bufferSize: Int) throws -> [UInt8]
	func persist<T:Encodable>(_ data: T) throws -> URL
	func uploads() -> [URL]
}

extension MLFPersistence {
	func md5File(url: URL, bufferSize: Int = 1048576) throws -> [UInt8] { return try self.md5File(url: url, bufferSize: bufferSize)}
}

class MLFDefaultPersistence: MLFPersistence {
	private let fileManager: FileManager
	private let sdkDirectoryPath: URL
	private let modelDirectoryUrl: URL
	private let uploadsDirectoryUrl: URL
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
		self.uploadsDirectoryUrl = self.sdkDirectoryPath
			.appendingPathComponent("uploads", isDirectory: true)
		self.initLocalFolders()
	}
	
	func uploads() -> [URL] {
		do {
			return  try self.fileManager.contentsOfDirectory(
				at: self.uploadsDirectoryUrl,
				includingPropertiesForKeys: nil,
				options: []
			)
		} catch {
			self.log.d(tag: "MLFPersistence", "Failed to get all files in upload directory. \(error)")
			return []
		}
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
		guard let metadata = self.findDownloadMetadata(for: token) else {
			return (nil, nil)
		}
		
		return (try self.modelFileFor(model: metadata), metadata)
	}
	
	private func findDownloadMetadata(for token: String) -> MLFDownloadMetadata? {
		if let metadata = self.metadataMap[token] {
			return metadata
		}
		
		do {
			let path = try self.directoryFor(token: token)
			let metadataUrl = path.appendingPathComponent(".metadata")
			if (!self.exists(file: metadataUrl)) {
				return nil
			}
			let data = try Data(contentsOf: metadataUrl)
			let metadata = try decoder.decode(MLFDownloadMetadata.self, from: data)
			self.metadataMap[token] = metadata
			
			return metadata
		} catch {
			self.log.d("Failed to read metadata for token \(token): \(error)")
			return nil
		}
	}
	
	@discardableResult
	func save(_ metadata: MLFDownloadMetadata, for token: String) throws -> URL {
		do {
			let path = try self.directoryFor(token: token)
			let metadataUrl = path.appendingPathComponent(".metadata")
			try self.write(metadata, to: metadataUrl)
			self.metadataMap[token] = metadata
			return metadataUrl
		} catch {
			self.log.d("Failed to write metadata for token \(token): \(error)")
			throw error
		}
	}
	
	func persist<T:Encodable>(_ data: T) throws -> URL {
		let fileId = UUID().uuidString
		let file = self.uploadsDirectoryUrl.appendingPathComponent("\(fileId)")
		try self.write(data, to: file)
		
		return file
	}
	
	private func write<T: Encodable>(_ input: T, to url: URL) throws {
		var options: Data.WritingOptions = [.atomic]
		#if os(iOS) || os(watchOS) || os(tvOS)
		options.insert(.completeFileProtectionUnlessOpen)
		#endif
		
		let data = try self.encoder.encode(input)
		try data.write(to: url, options: options)
	}
	
	func directoryFor(token: String) throws -> URL {
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
		
		let path = try self.directoryFor(token: model.token)
		return path.appendingPathComponent(activeVersion)
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
			try self.fileManager.createDirectory(at: uploadsDirectoryUrl, withIntermediateDirectories: true)
			
			var sdkDirectoryPath = self.sdkDirectoryPath
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = true
			try sdkDirectoryPath.setResourceValues(resourceValues)
		} catch {
			self.log.e("Failed to initialize local directories: \(error)")
		}
	}
}
