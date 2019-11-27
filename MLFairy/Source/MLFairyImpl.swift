//
//  MLFairyImpl.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Promises
import Combine
import MLFSupport

class MLFairyImpl {
	private let log: MLFLogger
	private let app: MLFApp
	private let device: MLFDevice
	private let persistence: MLFPersistence
	private let network: MLFNetwork
	private let collector: MLFPredictionCollector
	private let extractor: MLFModelDataExtractor
	private let upload: MLFUploadTask
	private let support: MLFSupport
	private let encryption: MLFEncryptionClient
	
	private let requestQueue: DispatchQueue
	private let computationQueue: DispatchQueue
	private let compilationQueue: DispatchQueue
	private let eventQueue: DispatchQueue
	
	private var pokeSubscription: AnyCancellable?
	private var modelInfoSubscription: AnyCancellable?
	
	convenience init() {
		let fileManger = FileManager.default;
		let root = fileManger.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
		self.init(fileManager: fileManger, persistenceRoot: root)
	}
	
	init(fileManager: FileManager, persistenceRoot: URL) {
		self.requestQueue = DispatchQueue(label: "com.mlfairy.requestQueue")
		self.computationQueue = DispatchQueue(label: "com.mlfairy.computation")
		self.compilationQueue = DispatchQueue(label: "com.mlfairy.compilation")
		self.eventQueue = DispatchQueue(
			label: "com.mlfairy.event",
			attributes: [.concurrent]
		)
		
		self.support = MLFSupport()
		self.network = MLFNetwork()
		self.log = MLFDefaultLogger()
		self.device = MLFDevice(host: MLFHostDevice())
		self.persistence = MLFDefaultPersistence(
			fileManager: fileManager,
			root: persistenceRoot,
			log: self.log
		)
		self.upload = MLFUploadTask(
			persistence: self.persistence,
			network: self.network,
			log: self.log,
			queue: self.eventQueue
		)
		self.app = MLFApp(logger:self.log, device:self.device)
		self.extractor = MLFModelDataExtractor(support: self.support)
		self.encryption = MLFEncryptionClient(
			app: self.app,
			support: self.support,
			network: self.network,
			log: self.log,
			queue: requestQueue
		)
		self.collector = MLFPredictionCollector(
			app: self.app,
			extractor: self.extractor,
			upload: self.upload,
			encryption: self.encryption,
			queue: self.eventQueue
		)
		
		self.pokeSubscription = self.upload.poke().sink(
			receiveCompletion: { [unowned self] _ in
				self.pokeSubscription = nil
			}, receiveValue: {_ in}
		)
	}
	
	func getCoreMLModel(
		token: String,
		options: MLFairy.Options,
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
				info: self.app.info,
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
			
			let modelIdentifier = MLFModelId(metadata: metadata)
			var mlfModel: MLFModel? = nil
			if let model = compilation.model {
				mlfModel = self.wrap(model, identifier: modelIdentifier)
			}
			return MLFModelResult(
				result: result,
				compiledModel: compilation.model,
				compiledModelUrl: compilation.compiledModelUrl,
				downloadedModelUrl: url,
				mlFairyModel: mlfModel
			)
		}.then(on: queue) { model in
			callback(model)
		}.catch(on: queue) { error in
			let result = Result<MLModel?, Error>(value:nil, error: error)
			let model = MLFModelResult(
				result: result,
				compiledModel: nil,
				compiledModelUrl: nil,
				downloadedModelUrl: nil,
				mlFairyModel: nil
			)
			callback(model)
		}
	}
	
	func wrap(_ model: MLModel, token: String) -> MLFModel {
		let identifier = MLFModelId(token: token, downloadId: nil)
		return self.wrap(model, identifier: identifier)
	}
	
	func collect(
		token: String,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		elapsed: DispatchTimeInterval
	) {
		self.collector.collect(
			for: MLFModelId(token: token, downloadId: nil),
			input: input,
			output: output,
			elapsed: elapsed,
			options: nil
		)
	}
	
	private func wrap(_ model: MLModel, identifier: MLFModelId) -> MLFModel {
		let info = self.extractor.modelInformation(model: model);
		let modelInfo = MLFModelInfo(modelId: identifier, info: info)
		self.modelInfoSubscription = self.upload.queue(modelInfo).sink(
			receiveCompletion: { [unowned self] _ in
				self.modelInfoSubscription = nil
			}, receiveValue: {_ in}
		)
		return MLFModel(
			model: model,
			identifier: identifier,
			collector: self.collector,
			log: self.log
		)
	}
}
