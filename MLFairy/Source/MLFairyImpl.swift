//
//  MLFairyImpl.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

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
	
	private var requestMap:[String: MLFModelTask] = [:]
	
	private let requestQueue: DispatchQueue
	private let computationQueue: DispatchQueue
	private let compilationQueue: DispatchQueue
	
	private var userId: String?
	
	init() {
		self.network = MLFNetwork()
		self.log = MLFLogger()
		self.device = MLFDevice()
		self.persistence = MLFPersistence(log: self.log)
		self.app = MLFApp(logger:self.log, device:self.device)
		
		self.computationQueue = DispatchQueue(label: "com.mlfairy.computation")
		self.requestQueue = DispatchQueue(label: "com.mlfairy.requestQueue", target: self.computationQueue)
		self.compilationQueue = DispatchQueue(label: "com.mlfairy.compilation", target: self.computationQueue)
	}
	
	func getCoreMLModel(
		token: String,
		options: Options = [.fallbackDisk],
		queue: DispatchQueue,
		callback: @escaping (MLModel?, Error?) -> Void
	) {
		// TODO: Cleanup requestMap?
		self.download(
			model:token
		).response(
			queue: queue,
			callback
		)
	}
	
	func set(userId: String, forModel modelToken: String?) {
		self.requestQueue.async {
			if let token = modelToken {
				self.task(for: token).set(userId: userId)
			} else {
				self.userId = userId
				self.requestMap.forEach { (_, task) in
					task.set(userId: userId)
				}
			}
		}
	}
	
	func watch(model: Any, forToken: String) {
		
	}
	
	private func download(model modelId: String) -> MLFModelTask {
		let task = self.task(for: modelId)
		self.perform(task)
		
		return task
	}
	
	private func task(for modelId: String) -> MLFModelTask {
		if let task = self.requestMap[modelId] {
			return task
		}
		
		let task = MLFModelTask(
			token: modelId,
			app: self.app,
			network: self.network,
			persistence: self.persistence,
			computationQueue: self.computationQueue,
			compilationQueue: self.compilationQueue,
			log: self.log
		)
		self.requestMap[modelId] = task
		
		return task
	}
	
	private func perform(_ task: MLFModelTask) {
		self.requestQueue.async {
			task.resume()
		}
	}
}
