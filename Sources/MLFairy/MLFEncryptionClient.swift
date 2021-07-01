//
//  MLFEncryptionClient.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Combine
import Alamofire
import MLFSupport

class MLFEncryptionClient {
	private let support: MLFTools
	private let network: MLFNetwork
	private let log: MLFLogger
	private let queue: DispatchQueue
	private var keys: [MLFModelId: MLFEncryptor] = [:]
	private let app: MLFApp
	
	init(
		app: MLFApp,
		support: MLFTools,
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
	
	func encrypt(prediction: MLFPrediction) -> AnyPublisher<MLFEncryptedData, Error> {
		return self.encryptor(id: prediction.modelId)
			.flatMap { cryptor -> Future<MLFEncryptedData, Error> in
				return self.encrypt(prediction: prediction, with: cryptor)
			}.eraseToAnyPublisher()
	}
	
	private func encrypt(prediction: MLFPrediction, with encryptor: MLFEncryptor) -> Future<MLFEncryptedData, Error> {
		return Future<MLFEncryptedData, Error> { promise in
			do {
				// TODO: You might not want to do this on this thread if encryption takes a long time (this thread is serial)
				let data = try encryptor.encrypt(prediction)
				promise(.success(data))
			} catch {
				promise(.failure(error))
			}
		}
	}
	private func encryptor(id: MLFModelId) -> Future<MLFEncryptor, Error> {
		return Future<MLFEncryptor, Error>.run(on: self.queue) { promise in
			if let key = self.keys[id] {
				promise(.success(key))
			} else {
				let body: [String: Any] = ["token": id.token, "data": self.app.info]
				let request = self.network
					.encryption(body)
					.responseDecodable(queue: self.queue) { (response: DataResponse<MLFEncryptionData, AFError>) in
						let encryption = self.onDownloadEncryption(response)
						let encryptor = MLFEncryptor(encryption, support: self.support)
						self.keys[id] = encryptor
						promise(.success(encryptor))
					}
				
				request.resume()
			}
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
				return MLFEncryptionData(
					id: "23TeglyK7Yq8VPqYwbwf",
					publicKey: "MIIBCgKCAQEAnVAbjBm6nAfK+tozbJ+japVTplh0QY0sCNDmc0QFTSFDxs9Lxl9T\nXVNnAVif2lrCoCD/03BW2nUuNH0Co44S7XWTb0EwdGRpzqJFb6+BgTXLgsDxXLA6\nNWa6kjh+2UyfAAdcrcu+kaxeR+jov6X/ws0XURgAQus+BafnW++V0vn46KJpGuAB\nv4Ya8YutLzNg0UbExjGe2tICl3MAnhDtjXDRpKjIwojS1GQZu5EO+Ic3fRZNuf0v\nwFqEnsc+OFQRcBlhVmvkT6FU9dcJ1KGcD+wRl3IUwDsCD9h6dDDOrnxzafsrWLzI\nauQtKa9ikxW3ITkxkU07KuFPMZIsIeynmwIDAQAB"
			)
		}
	}
}
