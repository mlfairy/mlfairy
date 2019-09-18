//
//  MLFModel.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

public class MLFModel: MLModel {
	private let model: MLModel
	private let identifier: MLFModelId

	private let collector: MLFPredictionCollector
	private let log: MLFLogger
	
	/// A model holds a description of its required inputs and expected outputs.
	public override var modelDescription: MLModelDescription {
		return model.modelDescription
	}
	
	/// The load-time parameters used to instantiate this MLModel object.
	@available(iOS 12.0, macOS 10.14, tvOS 12.0, *)
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
	@available(iOS 12.0, macOS 10.14, tvOS 12.0, *)
	public convenience init(contentsOf url: URL, configuration: MLModelConfiguration) throws { throw MLFModelError.notSupported }
	
	/// All models can predict on a specific set of input features.
	override public func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
		let prediction = try self.model.prediction(from: input)
		
		self.collector.collect(
			for:self.identifier,
			input: input,
			output: prediction
		)
		
		return prediction
	}
	
	
	/// Prediction with explict options
	override public func prediction(from input: MLFeatureProvider, options: MLPredictionOptions) throws -> MLFeatureProvider {
		let prediction = try self.model.prediction(from: input, options: options)
		
		self.collector.collect(
			for:self.identifier,
			input: input,
			output: prediction,
			options: options
		)

		return prediction
	}
	
	
	/// Batch prediction with explict options
	@available(iOS 12.0, macOS 10.14, tvOS 12.0, *)
	override public func predictions(from inputBatch: MLBatchProvider, options: MLPredictionOptions) throws -> MLBatchProvider {
		let predictions = try self.model.predictions(from: inputBatch, options: options)
		return predictions
	}
}
