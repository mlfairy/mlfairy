//
//  MLFUploadTask.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Combine
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
	func poke() -> AnyPublisher<[URL], Error> {
		return Future<[URL], Error>.run(on: queue) { promise in
			let files = self.persistence.uploads()
			promise(.success(files))
		}.flatMap(upload).eraseToAnyPublisher()
	}
	
	@discardableResult
	func queue<T: Encodable>(
		_ uploadable: T,
		filename: String = UUID().uuidString
	) -> AnyPublisher<[URL], Error> {
		return Future<[URL], Error>.run(on: queue) { promise in
			let file = try self.persistence.persist(uploadable, filename: filename)
			promise(.success([file]))
		}.flatMap(upload).eraseToAnyPublisher()
	}
	
	private func upload(files: [URL]) -> AnyPublisher<[URL], Error> {
		if files.count == 0 {
			return Empty(completeImmediately: true).eraseToAnyPublisher()
		}
		
		return Publishers.MergeMany(files.map(perform))
			.collect()
			.eraseToAnyPublisher()
	}
	
	private func perform(_ file: URL) -> AnyPublisher<URL, Error> {
		return Future<URL, Error>.run(on: queue) { promise in
			let data = try String(contentsOf: file, encoding: .utf8)
			let body: [String: Any] = ["event": data]
			let request = self.network
				.event(body)
				.responseDecodable(queue: self.queue) { (response: DataResponse<MLFUploadResponse, AFError>) in
					switch(response.result) {
					case .success:
						self.persistence.deleteFile(at: file)
						promise(.success(file))
					case .failure(let error):
						self.log.d(tag: "MLFUploadTask", "Failed to upload [\(file)]. Skipping file.\(error)")
						promise(.failure(error))
					}
				}
			
			request.resume()
		}
		.retry(2)
		.eraseToAnyPublisher()
	}
}


