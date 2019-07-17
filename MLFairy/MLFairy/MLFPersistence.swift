//
//  MLFPersistence.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFPersistence {
	typealias OnDiskDownloadMetadata = (url: URL?, metadata: MLFDownloadMetadata?)
	
	private let fileManager: FileManager
	private let sdkDirectoryPath: URL
	private let modelDirectoryUrl: URL
	private let log: MLFLogger
	
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	
	private var metadataMap: [String: MLFDownloadMetadata] = [:]
	
	init(log: MLFLogger) {
		self.fileManager = FileManager.default
		self.log = log
		self.sdkDirectoryPath = self.fileManager
			.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
			.appendingPathComponent("com.mlfairy", isDirectory: true)
		self.modelDirectoryUrl = self.sdkDirectoryPath
			.appendingPathComponent("models", isDirectory: true)
		
		self.initLocalFolders()
	}
	
	func exists(file: URL) -> Bool {
		return self.fileManager.fileExists(atPath: file.path)
	}
	
	func size(url: URL) -> Int? {
		do {
			let resources = try url.resourceValues(forKeys: [.fileSizeKey])
			return resources.fileSize
		} catch {
			self.log.d("Failed to get size for directory \(url): \(error)")
			return nil
		}
	}
	
	func findModel(for token: String) -> OnDiskDownloadMetadata {
		guard let metadata = self.findDownloadMetadata(for: token) else {
			return (nil, nil)
		}
		
		return (self.modelFileFor(model: metadata), metadata)
	}
	
	func findDownloadMetadata(for token: String) -> MLFDownloadMetadata? {
		if let metadata = self.metadataMap[token] {
			return metadata
		}
		
		guard let path = self.directoryFor(token: token) else {
			return nil
		}
		
		let metadataUrl = path.appendingPathComponent(".metadata")
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
	
	func save(_ metadata: MLFDownloadMetadata, for token: String) {
		guard let path = self.directoryFor(token: token) else {
			return
		}
		
		let metadataUrl = path.appendingPathComponent(".metadata")
		do {
			let data = try self.encoder.encode(metadata)
			try data.write(to: metadataUrl, options: [.atomic, .completeFileProtectionUnlessOpen])
			self.metadataMap[token] = metadata
		} catch {
			self.log.d("Failed to write metadata for token \(token): \(error)")
		}
	}
	
	func directoryFor(token: String) -> URL? {
		do {
			let modelDirectory = self.modelDirectoryUrl
				.appendingPathComponent(token, isDirectory: true)
			try self.fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
			
			return modelDirectory
		} catch {
			self.log.d("Failed to create model directory for token \(token): \(error)")
			return nil
		}
	}
	
	func modelFileFor(model: MLFDownloadMetadata) -> URL? {
		guard let activeVersion = model.activeVersion else { return nil }
		
		if let path = self.directoryFor(token: model.token) {
			return path.appendingPathComponent(activeVersion)
		}
		
		return nil
	}
	
	func metadataFileFor(model: MLFDownloadMetadata) -> URL? {
		if let path = self.directoryFor(token: model.token) {
			return path.appendingPathComponent(".metadata")
		}
		
		return nil
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
