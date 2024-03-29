//
//  MLFEventCollector.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Combine

class MLFPredictionCollector {
	private let extractor: MLFModelDataExtractor
	private let upload: MLFUploadTask
	private let queue: DispatchQueue
	private let app: MLFApp
	private let encryption: MLFEncryptionClient
	
	init(
		app: MLFApp,
		extractor: MLFModelDataExtractor,
		upload: MLFUploadTask,
		encryption: MLFEncryptionClient,
		queue: DispatchQueue
	) {
		self.app = app
		self.extractor = extractor
		self.upload = upload
		self.encryption = encryption
		self.queue = queue
	}
	
	@discardableResult
	func collect(
		for model: MLFModelId,
		input: MLFeatureProvider,
		output: MLFeatureProvider,
		elapsed: DispatchTimeInterval,
		options: MLPredictionOptions? = nil
	) -> AnyPublisher<[URL], Error> {
		return Future<MLFPrediction, Error>.run(on: self.queue) { promise in
			let results = self.extractor.convert(input: input, output: output)
			let prediction = MLFPrediction(
				modelId: model,
				input: results.input,
				output: results.output,
				appInfo: self.app.info,
				elapsed: self.toDouble(elapsed)
			)
			promise(.success(prediction))
		}
		.flatMap(self.encryption.encrypt)
		.flatMap { self.upload.queue($0) }
		.eraseToAnyPublisher()
	}
	
	private func toDouble(_ interval: DispatchTimeInterval) -> Double? {
        switch interval {
        case .seconds(let value):
            return Double(value)
        case .milliseconds(let value):
            return Double(value) * 0.001
        case .microseconds(let value):
            return Double(value) * 0.000001
        case .nanoseconds(let value):
            return Double(value) * 0.000000001
        default:
			return nil
        }
    }
}
