//
//  MLFairyImpl.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
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
	private let support: MLFTools
	private let encryption: MLFEncryptionClient
	
	private let requestQueue: DispatchQueue
	private let computationQueue: DispatchQueue
	private let compilationQueue: DispatchQueue
	private let eventQueue: DispatchQueue
	
	private var pokeSubscription: AnyCancellable?
	private var modelInfoSubscription: AnyCancellable?
	private var downloadSubscriptions = [AnyCancellable]()
	
	convenience init() {
		let fileManger = FileManager.default;
		let root = fileManger.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
		self.init(fileManager: fileManger, persistenceRoot: root)
	}
	
	init(fileManager: FileManager, persistenceRoot: URL, environment: APIEnvironment = .prod) {
		self.requestQueue = DispatchQueue(label: "com.mlfairy.requestQueue")
		self.computationQueue = DispatchQueue(label: "com.mlfairy.computation")
		self.compilationQueue = DispatchQueue(label: "com.mlfairy.compilation")
		self.eventQueue = DispatchQueue(
			label: "com.mlfairy.event",
			attributes: [.concurrent]
		)
		
		self.support = MLFTools()
		self.network = MLFNetwork(environment: environment)
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
	
	// TODO: Currently, we're leaking the subscriptions
	func getCoreMLModel(
		token: String,
		options: MLFairy.Options,
		queue: DispatchQueue,
		callback: @escaping (MLFModelResult) -> Void
	) {
		self.coreMLModelPublisher(token: token, options: options)
			.receive(on: queue)
			.sink(receiveCompletion: {_ in}, receiveValue: { callback($0) })
			.store(in: &downloadSubscriptions)
	}
	
	func coreMLModelPublisher(
		token: String,
		options: MLFairy.Options
	) -> AnyPublisher<MLFModelResult, Error> {
		let task = MLFDownloadTask(
			network: self.network,
			persistence: self.persistence,
			log: self.log
		)
		
		return self.findMetadata(for: token)
			.flatMap {
				return task.downloadMetadata(
					token,
					info: self.app.info,
					fallback: $0.metadata,
					on: self.computationQueue
				)
			}.handleEvents(receiveOutput: {
				do { try self.persistence.save($0, for: token) } catch {}
			}).flatMap {
				return self.downloadModel(with: task, metadata: $0, on: self.computationQueue)
					.combineLatest(Future<MLFDownloadMetadata, Error>.just($0))
			}.receive(on: self.compilationQueue).flatMap {
				return self.compileModel(with: task, url: $0, metadata: $1)
			}.catch { error -> Future<MLFModelResult, Error> in
				let result = Result<MLModel?, Error>(value:nil, error: error)
				let model = MLFModelResult(
					result: result,
					compiledModel: nil,
					compiledModelUrl: nil,
					downloadedModelUrl: nil,
					mlFairyModel: nil
				)

				return Future<MLFModelResult, Error>.just(model)
			}.eraseToAnyPublisher()
	}
	
	private func findMetadata(for token: String) -> Future<OnDiskDownloadMetadata, Error> {
		return Future<OnDiskDownloadMetadata, Error>.run(on: requestQueue) { promise in
			do {
				let diskMetadata = try self.persistence.findModel(for: token)
				promise(.success(diskMetadata))
			} catch {
				promise(.failure(error))
			}
		}
	}
	
	private func downloadModel(
		with task: MLFDownloadTask,
		metadata: MLFDownloadMetadata,
		on queue: DispatchQueue
	) -> AnyPublisher<URL, Error> {
		return Future<URL, Error> { promise in
			do {
				let destination = try self.persistence.modelFileFor(model: metadata)!
				promise(.success(destination))
			} catch {
				promise(.failure(error))
			}
		}.flatMap { destination -> Future<URL, Error> in
			return task.downloadModel(
				metadata,
				to: destination,
				on: queue
			)
		}.eraseToAnyPublisher()
	}
	
	private func compileModel(
		with task: MLFDownloadTask,
		url: URL,
		metadata: MLFDownloadMetadata
	) -> AnyPublisher<MLFModelResult, Error> {
		return task.compileModel(url, metadata)
			.map { compilation -> MLFModelResult in
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
			}.eraseToAnyPublisher()
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
