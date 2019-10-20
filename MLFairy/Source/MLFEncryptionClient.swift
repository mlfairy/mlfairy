//
//  MLFEncryptionClient.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Promises
import Alamofire

class MLFEncryptionClient {
	private let network: MLFNetwork
	private let log: MLFLogger
	private let queue: DispatchQueue
	private var keys: [MLFModelId: MLFEncryptionData] = [:]
	
	init(
		network: MLFNetwork,
		log: MLFLogger,
		queue: DispatchQueue
	) {
		self.network = network
		self.log = log
		self.queue = queue
	}
	
	func encrypt(prediction: MLFPrediction) -> Promise<MLFEncryptedData> {
		return self.keys(id: prediction.modelId)
			.then(on: self.queue) { (keys) -> MLFEncryptedData in
				let encrypted = "" // TODO Encrypt prediction using encryption.publicKey
				let data = MLFEncryptedData(encryptionId: keys.id, data: encrypted)
				return data
			}
	}
	
	private func keys(id: MLFModelId) -> Promise<MLFEncryptionData> {
		return Promise<MLFEncryptionData>(on: self.queue) { () -> Promise<MLFEncryptionData> in
			if let key = self.keys[id] {
				let promise = Promise<MLFEncryptionData>.pending()
				promise.fulfill(key)
				return promise
			}
			
			return self.fetch(id, queue: self.queue)
		}
	}
	
	private func fetch(_ id: MLFModelId, queue: DispatchQueue) -> Promise<MLFEncryptionData> {
		return Promise<MLFEncryptionData>(on: queue) { resolve, reject in
			let body: [String: Any] = ["token": id.token]
			let request = self.network
				.encryption(body)
				.responseDecodable(queue: queue) { (response: DataResponse<MLFEncryptionData, AFError>) in
					let encryption = self.onDownloadEncryption(response)
					resolve(encryption)
				}
			
			request.resume()
		}.then(on: queue) { encryption in
			self.keys[id] = encryption
		}
	}
	
	private func onDownloadEncryption(
		_ response: DataResponse<MLFEncryptionData, AFError>
	) -> MLFEncryptionData  {
		switch(response.result) {
			case .success(let value):
				self.log.d("Successfully downloaded encryption")
				return value
			case .failure(let failure):
				self.log.d("Failed to download encryption \(failure.errorDescription ?? ""). Using default keys")
				return MLFEncryptionData(id: "1234567890", publicKey: "mlfairy")
		}
	}
}
