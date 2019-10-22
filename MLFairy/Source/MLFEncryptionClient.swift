//
//  MLFEncryptionClient.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Promises
import Alamofire
import MLFSupport

class MLFEncryptionClient {
	private let support: MLFSupport
	private let network: MLFNetwork
	private let log: MLFLogger
	private let queue: DispatchQueue
	private var keys: [MLFModelId: MLFEncryptor] = [:]
	private let app: MLFApp
	
	init(
		app: MLFApp,
		support: MLFSupport,
		network: MLFNetwork,
		log: MLFLogger,
		queue: DispatchQueue
	) {
		self.app = app
		self.support = support
		self.network = network
		self.log = log
		self.queue = queue
	}
	
	func encrypt(prediction: MLFPrediction) -> Promise<MLFEncryptedData> {
		return self.keys(id: prediction.modelId)
			.then(on: self.queue) { (encryptor) -> MLFEncryptedData in
				// TODO: You might not want to do this on this thread if encryption takes a long time (this thread is serial)
				return try encryptor.encrypt(prediction)
			}
	}
	
	private func keys(id: MLFModelId) -> Promise<MLFEncryptor> {
		return Promise<MLFEncryptor>(on: self.queue) { () -> Promise<MLFEncryptor> in
			if let key = self.keys[id] {
				let promise = Promise<MLFEncryptor>.pending()
				promise.fulfill(key)
				return promise
			}
			
			return self.fetch(id, queue: self.queue)
				.then(on: self.queue) { (encryption) -> MLFEncryptor in
					let encryptor = MLFEncryptor(encryption, support: self.support)
					self.keys[id] = encryptor
					
					return encryptor
				}
		}
	}
	
	private func fetch(_ id: MLFModelId, queue: DispatchQueue) -> Promise<MLFEncryptionData> {
		return Promise<MLFEncryptionData>(on: queue) { resolve, reject in
			let body: [String: Any] = ["token": id.token, "data": self.app.info]
			let request = self.network
				.encryption(body)
				.responseDecodable(queue: queue) { (response: DataResponse<MLFEncryptionData, AFError>) in
					let encryption = self.onDownloadEncryption(response)
					resolve(encryption)
				}
			
			request.resume()
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
				return MLFEncryptionData(id: "23TeglyK7Yq8VPqYwbwf", publicKey: "MIIBCgKCAQEAnVAbjBm6nAfK+tozbJ+japVTplh0QY0sCNDmc0QFTSFDxs9Lxl9T\nXVNnAVif2lrCoCD/03BW2nUuNH0Co44S7XWTb0EwdGRpzqJFb6+BgTXLgsDxXLA6\nNWa6kjh+2UyfAAdcrcu+kaxeR+jov6X/ws0XURgAQus+BafnW++V0vn46KJpGuAB\nv4Ya8YutLzNg0UbExjGe2tICl3MAnhDtjXDRpKjIwojS1GQZu5EO+Ic3fRZNuf0v\nwFqEnsc+OFQRcBlhVmvkT6FU9dcJ1KGcD+wRl3IUwDsCD9h6dDDOrnxzafsrWLzI\nauQtKa9ikxW3ITkxkU07KuFPMZIsIeynmwIDAQAB")
		}
	}
}
