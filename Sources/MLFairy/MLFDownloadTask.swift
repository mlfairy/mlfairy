//
//  MLFTask.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Combine
import CoreML
import Alamofire

class MLFDownloadTask {
	private let network: MLFNetwork
	private let persistence: MLFPersistence
	private let log: MLFLogger
	
	init(
		network: MLFNetwork,
		persistence: MLFPersistence,
		log: MLFLogger
	) {
		self.network = network
		self.persistence = persistence
		self.log = log
	}
	
	func downloadMetadata(
		_ token: String,
		info:[String: String],
		fallback: MLFDownloadMetadata?,
		on queue: DispatchQueue
	) -> Future<MLFDownloadMetadata, Error> {
		return Future<MLFDownloadMetadata, Error>{ promise in
			let body: [String: Any] = ["token": token, "data": info]
			let request = self.network
				.metadata(body)
				.responseDecodable(queue: queue) { (response: DataResponse<MLFDownloadMetadata, AFError>) in
					do {
						let metadata = try self.onDownloadMetadata(response, fallback)
						promise(.success(metadata))
					} catch {
						promise(.failure(error))
					}
				}
			
			request.resume()
		}
	}
	
	func downloadModel(
		_ metadata: MLFDownloadMetadata,
		to destination: URL,
		on queue: DispatchQueue
	) -> Future<URL, Error> {
		return Future<URL, Error>.run(on: queue) { promise in
			do {
				if try self.persistence.exists(file: destination) {
					self.log.d("Skipping download. \(destination) exists. Will use existing file.")
					try self.performChecksum(destination, with: metadata)
					promise(.success(destination))
				} else {
					self.log.d("Downloading model into \(destination)")
					let request = self.network
						.download(metadata.modelFileUrl!, into: destination)
						.response(queue: queue) { (response: DownloadResponse<URL?, AFError>) in
							do {
								let url = try self.onDownloadModel(response, metadata)
								promise(.success(url))
							} catch {
								promise(.failure(error))
							}
						}
					
					request.resume()
				}
			} catch {
				promise(.failure(error))
			}
		}
	}
	
	func compileModel(_ url: URL, _ metadata: MLFDownloadMetadata) -> Future<(compiledModelUrl: URL?, model: MLModel?), Error> {
		return Future<(compiledModelUrl: URL?, model: MLModel?), Error> { promise in
			do {
				#if os(watchOS)
				let compiledUrl: URL? = nil
				let model: MLModel? = nil
				promise(.success((compiledUrl, model)))
				#else
				let compiledUrl = try MLModel.compileModel(at: url)
				let model = try MLModel(contentsOf: compiledUrl)
				promise(.success((compiledUrl, model)))
				#endif
			} catch {
				promise(.failure(MLFError.compilationFailed(
					message: "Failed to compile model for token \(metadata.token)",
					reason: error
				)))
			}
		}
	}
	
	private func onDownloadMetadata(
		_ response: DataResponse<MLFDownloadMetadata, AFError>,
		_ fallback: MLFDownloadMetadata?
	) throws -> MLFDownloadMetadata  {
		switch(response.result) {
			case .success(let value):
				self.log.d("Successfully downloaded metadata:\n\(value.debugDescription)")
				return try self.checkMetadata(value)
			case .failure(let failure):
				let error = MLFNetwork.remapToMLFErrorIfNecessary(failure, data:response.data)
				if let fallback = fallback { return try self.checkMetadata(fallback) }
				throw MLFError.downloadFailed(message: "Failed to download model metadata", reason: error)
		}
	}
	
	private func checkMetadata(_ metadata: MLFDownloadMetadata) throws -> MLFDownloadMetadata {
		guard let _ = metadata.activeVersion, let _ = metadata.modelFileUrl else {
			throw MLFError.noDownloadAvailable
		}
		
		return metadata
	}
	
	private func onDownloadModel(
		_ response: DownloadResponse<URL?, AFError>,
		_ metadata: MLFDownloadMetadata
	) throws -> URL {
		switch(response.result) {
		case .success(let value):
			try self.performChecksum(value!, with:metadata)
			return value!
		case .failure(let failure):
			throw MLFError.downloadFailed(
				message:"Failed to download model for \(metadata.token)",
				reason: failure
			)
		}
	}
	
	private func performChecksum(_ url: URL, with metadata: MLFDownloadMetadata) throws {
		guard let hash = metadata.hash, let algorithm = metadata.algorithm else {
			self.log.d("No hash or algorithm in metadata. Skipping checksum.")
			return;
		}
		
		guard algorithm.lowercased() == "md5" else {
			self.log.d("Unsupported checksum algorithm \(algorithm). Skipping checksum.")
			return;
		}
		
		do {
			let checksumDigest = try self.persistence.md5File(url: url)
			let data = Data(checksumDigest)
			let checksum = data.base64EncodedString(); // digest.map { String(format: "%02hhx", $0) }.joined()
			if checksum != hash {
				throw MLFError.failedChecksum
			}
		} catch MLFError.failedChecksum {
			self.log.d("Checksum failed. Deleting file from disk.")
			self.persistence.deleteFile(at: url)
			throw MLFError.failedChecksum
		} catch {
			throw MLFError.checksumError(error: error)
		}
	}
}
