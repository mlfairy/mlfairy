//
//  MLFUploadTask.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Promises
import Alamofire

class MLFUploadTask {
	private let persistence: MLFPersistence
	private let network: MLFNetwork
	private let log: MLFLogger
	private let queue: DispatchQueue
	
	init(
		persistence: MLFPersistence,
		network: MLFNetwork,
		log: MLFLogger,
		queue: DispatchQueue
	) {
		self.persistence = persistence
		self.network = network
		self.queue = queue
		self.log = log
	}
	
	@discardableResult
	func queue<T: Encodable>(_ uploadable: T) -> Promise<[URL]> {
		return Promise(on: self.queue) { () -> [URL] in
			let file = try self.persistence.persist(uploadable)
			return [file]
		}.then(on: self.queue) {
			return self.upload(files: $0)
		}
	}
	
	@discardableResult
	func poke() -> Promise<[URL]> {
		return Promise(on: self.queue) { () -> [URL] in
			return self.persistence.uploads()
		}.then(on: self.queue) {
			return self.upload(files: $0)
		}
	}
	
	private func upload(files: [URL]) -> Promise<[URL]> {
		if files.count == 0 {
			return Promise() {}
		}

		var promises: [Promise<URL>] = []
		for file in files {
			let promise = self.makePromise(file)
			promises.append(promise)
		}
		
		return all(promises)
	}
	
	private func makePromise(_ file: URL) -> Promise<URL> {
		let promise =  Promise(on: self.queue) { resolve, reject in
			// TODO: Should you have a policy of deleting files
			// TODO: Older than x days?
			let data = try String(contentsOf: file, encoding: .utf8)
			let body: [String: Any] = ["event": data]
			let request = self.network
				.event(body)
				.responseDecodable(queue: self.queue) { (response: DataResponse<MLFUploadResponse, AFError>) in
					switch(response.result) {
					case .success:
						resolve(file)
					case .failure(let error):
						reject(error)
					}
				}
			
			request.resume()
		}.then(on: self.queue) {
			self.persistence.deleteFile(at: $0)
		}.catch { error in
			self.log.d(tag: "MLFUploadTask", "Failed to upload [\(file)]. Skipping file.\(error)")
		}
		
		return retry(on: self.queue, attempts: 2, delay: 2, condition: nil) {
			return promise
		}
	}
}


