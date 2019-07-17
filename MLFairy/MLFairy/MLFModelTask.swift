//
//  MLModelTask.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Alamofire

class MLFModelTask {
	private struct MutableState {
		var userId: String?
		var error: Error?
		var downloadMetadata: MLFDownloadMetadata?
		var downloadMetadataRequest: DataRequest?
		var downloadFileUrl: URL?
		var downloadRequest: DownloadRequest?
		
		var compiledUrl: URL?
		var compiledModel: MLModel?
		var callbacks: [() -> Void] = []
	}
	private let protectedMutableState: MLFProtector<MutableState> = MLFProtector(MutableState())
	
	private let token: String
	
	private let app: MLFApp
	private let network: MLFNetwork
	private let log: MLFLogger
	private let persistence: MLFPersistence
	
	private let underlyingQueue: DispatchQueue
	private let compilationQueue: DispatchQueue
	
	init(
		token: String,
		app: MLFApp,
		network: MLFNetwork,
		persistence: MLFPersistence,
		computationQueue: DispatchQueue,
		compilationQueue: DispatchQueue,
		log: MLFLogger
	) {
		self.token = token
		self.network = network
		self.app = app
		self.underlyingQueue = computationQueue
		self.compilationQueue = compilationQueue
		self.log = log
		self.persistence = persistence
	}
	
	@discardableResult
	func set(userId: String) -> MLFModelTask {
		self.protectedMutableState.write { $0.userId = userId }
		// TODO: Notify server of userId. Is this even possible if there's no task being held by anyone?
		return self;
	}
	
	@discardableResult
	func resume() -> MLFModelTask {		
		self.underlyingQueue.async {
			let body: [String: Any] = [
				"token": self.token,
				"data": self.app.appInformation(),
			]
			
			let request = self.network
				.metadata(body)
				.responseDecodable(queue: self.underlyingQueue) { self.onDownloadResponse($0) }

			self.protectedMutableState.write{ $0.downloadMetadataRequest = request }
			request.resume()
		}
		
		return self;
	}
	
	@discardableResult
	func response(queue: DispatchQueue, _ callback: @escaping (MLModel?, Error?) -> Void) -> MLFModelTask {
		appendResponseQueue {
			var model: MLModel?
			var error: Error?
			self.protectedMutableState.read {
				model = $0.compiledModel
				error = $0.error
			}
			
			queue.async {
				callback(model, error)
			}
		}
		
		return self;
	}
	
	private func appendResponseQueue(_ closure: @escaping () -> Void) {
		self.protectedMutableState.write { state in
			state.callbacks.append(closure)
		}
	}
	
	private func onDownloadResponse(_ response: DataResponse<MLFDownloadMetadata>) {
		self.protectedMutableState.write{ $0.downloadMetadataRequest = nil }
		
		switch(response.result) {
		case .success(let value):
			self.didDownloadMetadata(value)
			break;
		case .failure(let failure):
			var error = failure
			if case AFError.responseSerializationFailed(_) = failure {
				if let data = response.data, let mlfError = MLFNetwork.decode(of: MLFErrorResponse.self, data) {
					error = MLFError.networkError(response: mlfError.message)
				}
			}
			
			let diskMetadata = self.persistence.findModel(for: self.token)
			if let _ = diskMetadata.url, let metadata = diskMetadata.metadata {
				self.log.d("Couldn't download model metadata for \(token). Will use version from disk: \(error)")
				self.didDownloadMetadata(metadata)
			} else {
				self.finish(error: MLFError.downloadFailed(message: "Failed to download model metadata for \(token)", reason: error))
			}

			break;
		}
	}
	
	private func didDownloadMetadata(_ metadata: MLFDownloadMetadata) {
		self.protectedMutableState.write { $0.downloadMetadata = metadata }
		// TODO: Notify server of userId if not already sent
		guard let _ = metadata.activeVersion, let url = metadata.modelFileUrl else {
			self.finish(error: MLFError.noDownloadAvailable)
			return;
		}
		
		if let destination = self.persistence.modelFileFor(model: metadata) {
			if self.persistence.exists(file: destination) {
				// TODO: Notify server we're using a version from disk
				self.didDownloadFile(url: destination)
			} else {
				self.download(url:url, into: destination, metadata)
			}
		}
	}
	
	private func download(url: String, into destination: URL, _ metadata: MLFDownloadMetadata) {
		self.log.d(tag: "MLFModelTask", "Downloading model into \(destination)")
		let request = self.network
			.download(url, into: destination)
			.response(queue: self.underlyingQueue) { self.onDownloadFileResponse($0) }
		
		self.persistence.save(metadata, for: self.token)
		self.protectedMutableState.write { $0.downloadRequest = request }
		
		request.resume()
	}
	
	private func onDownloadFileResponse(_ response: DownloadResponse<URL?>) {
		self.protectedMutableState.write { $0.downloadRequest = nil }
		switch(response.result) {
		case .success(let value):
			self.didDownloadFile(url: value!)
			break;
		case .failure(let failure):
			// TODO: Notify server of the failure
			self.finish(error: MLFError.downloadFailed(message:"Failed to download model for \(token)", reason: failure))
			break;
		}
	}
	
	private func didDownloadFile(url: URL) {
		self.protectedMutableState.write { $0.downloadFileUrl = url }
		self.compileModel(at: url)
	}
	
	private func compileModel(at url: URL) {
		// TODO: Should you store the compiledUrl in the metadata in someway?
		self.compilationQueue.async {
			do {
				let compiledUrl = try MLModel.compileModel(at: url)
				let model = try MLModel(contentsOf: compiledUrl)
				self.onCompiled(model: model, from:compiledUrl)
				self.finish()
			} catch {
				// TODO: Notify server of the failure
				self.finish(error:  MLFError.compilationFailed(message: "Failed to compile model for token \(self.token)", reason: error))
			}
		}
	}
	
	private func onCompiled(model: MLModel, from url: URL) {
		self.protectedMutableState.write {
			$0.compiledModel = model
			$0.compiledUrl = url
		}
		
		self.finish()
	}
	
	private func finish(error: MLFError? = nil) {
		if let error = error {
			switch(error) {
			case .compilationFailed(let message, let reason),
				 .downloadFailed(let message, let reason):
				self.log.e("\(message): \(reason)")
				break
			case .networkError(let response):
				self.log.e("\(response)")
				break
			case .noDownloadAvailable:
				self.log.i("No model available for download")
				break
			}
		}
		
		self.underlyingQueue.async {
			var completions: [() -> Void] = []
			
			self.protectedMutableState.write { state in
				state.error = error
				completions = state.callbacks
				state.callbacks.removeAll()
			}
			
			completions.forEach { $0() }
		}
	}
}
