//
//  MLFairyImpl2.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Promises

class MLFairyImpl {
	public struct Options: OptionSet {
		public static let fallbackDisk = Options(rawValue: 1)
		public static let fallbackNone = Options(rawValue: 2)
		
		public let rawValue: Int
		
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}
	
	private let log: MLFLogger
	private let app: MLFApp
	private let device: MLFDevice
	private let persistence: MLFPersistence
	private let network: MLFNetwork;
	
	private let requestQueue: DispatchQueue
	private let computationQueue: DispatchQueue
	private let compilationQueue: DispatchQueue
	
	private var cache:[Promise<MLModel>] = []
	
	convenience init() {
		let fileManger = FileManager.default;
		let root = fileManger.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
		self.init(fileManager: fileManger, persistenceRoot: root)
	}
	
	init(fileManager: FileManager, persistenceRoot: URL) {
		self.network = MLFNetwork()
		self.log = MLFDefaultLogger()
		self.device = MLFDevice(host: MLFHostDevice())
		self.persistence = MLFDefaultPersistence(
			fileManager: fileManager,
			root: persistenceRoot,
			log: self.log
		)
		self.app = MLFApp(logger:self.log, device:self.device)
		
		self.requestQueue = DispatchQueue(label: "com.mlfairy.requestQueue")
		self.computationQueue = DispatchQueue(label: "com.mlfairy.computation")
		self.compilationQueue = DispatchQueue(label: "com.mlfairy.compilation")
	}
	
	func getCoreMLModel(
		token: String,
		options: Options = [.fallbackDisk],
		queue: DispatchQueue,
		callback: @escaping (MLFModelResult) -> Void
	) {
		Promise<MLFModelResult>(on:self.requestQueue) { () -> MLFModelResult in
			let task = MLFDownloadTask(
				network: self.network,
				persistence: self.persistence,
				log: self.log
			)
			let diskMetadata = try self.persistence.findModel(for: token)
			let metadata = try await(task.downloadMetadata(
				token,
				info: self.app.appInformation(),
				fallback: diskMetadata.metadata,
				on: self.computationQueue
			))
			try self.persistence.save(metadata, for: token)
			let destination = try self.persistence.modelFileFor(model: metadata)!
			let url = try await(task.downloadModel(
				metadata,
				to: destination,
				on: self.computationQueue
			))
			
			let compilation = try await(task.compileModel(url, metadata, on: self.compilationQueue))
			let result = Result<MLModel?, Error>(value:compilation.model, error: nil)
			return MLFModelResult(
				result: result,
				compiledModel: compilation.model,
				compiledModelUrl: compilation.compiledModelUrl,
				downloadedModelUrl: url
			)
		}.then(on: queue) { model in
			callback(model)
		}.catch(on: queue) { error in
			let result = Result<MLModel?, Error>(value:nil, error: error)
			let model = MLFModelResult(
				result: result,
				compiledModel: nil,
				compiledModelUrl: nil,
				downloadedModelUrl: nil
			)
			callback(model)
		}
	}
}
