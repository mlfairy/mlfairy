//
//  MLFModel.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML
import Combine

public class MLFModel: MLModel {
	private let model: MLModel
	private let identifier: MLFModelId

	private let collector: MLFPredictionCollector
	private let log: MLFLogger
	private var subscriptions = [AnyCancellable]()
	
	/// A model holds a description of its required inputs and expected outputs.
	public override var modelDescription: MLModelDescription {
		return model.modelDescription
	}
	
	/// The load-time parameters used to instantiate this MLModel object.
	public override var configuration: MLModelConfiguration {
		return model.configuration
	}
	
	init(
		model: MLModel,
		identifier: MLFModelId,
		collector: MLFPredictionCollector,
		log: MLFLogger
	) {
		self.model = model
		self.identifier = identifier

		self.collector = collector
		self.log = log
	}
	
	public convenience init(contentsOf url: URL) throws { throw MLFModelError.notSupported }
	
	/// Construct a model given the location of its on-disk representation. Returns nil on error.
	public convenience init(contentsOf url: URL, configuration: MLModelConfiguration) throws { throw MLFModelError.notSupported }
	
	/// All models can predict on a specific set of input features.
	// TODO: Currently, we're leaking the subscriptions
	override public func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
		let start = DispatchTime.now()
		let prediction = try self.model.prediction(from: input)
		let end = DispatchTime.now()
		let diff = end.rawValue - start.rawValue
		let elapsed: DispatchTimeInterval = .nanoseconds(Int(diff))
		
		self.collector.collect(
			for: self.identifier,
			input: input,
			output: prediction,
			elapsed: elapsed
		).sink().store(in: &subscriptions)
		
		return prediction
	}

	/// Prediction with explict options
	// TODO: Currently, we're leaking the subscriptions
	override public func prediction(from input: MLFeatureProvider, options: MLPredictionOptions) throws -> MLFeatureProvider {
		let start = DispatchTime.now()
		let prediction = try self.model.prediction(from: input, options: options)
		let end = DispatchTime.now()
		let diff = end.rawValue - start.rawValue
		let elapsed: DispatchTimeInterval = .nanoseconds(Int(diff))

		self.collector.collect(
			for: self.identifier,
			input: input,
			output: prediction,
			elapsed: elapsed,
			options: options
		).sink().store(in: &subscriptions)

		return prediction
	}
	
	
	/// Batch prediction with explict options
	override public func predictions(from inputBatch: MLBatchProvider, options: MLPredictionOptions) throws -> MLBatchProvider {
		let predictions = try self.model.predictions(from: inputBatch, options: options)
		
		if inputBatch.count == predictions.count {
			for index in 0..<predictions.count {
				self.collector.collect(
					for: self.identifier,
					input: inputBatch.features(at: index),
					output: predictions.features(at: index),
					elapsed: .never
				)
			}
		}
		
		return predictions
	}
}
