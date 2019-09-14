//
//  MLFValueExtractor.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

protocol MLFValueExtractor {
	func extract(_ value: MLFeatureValue) -> Any?
}

class MLFPrimitiveValueExtractor: MLFValueExtractor {
	public func extract(_ value: MLFeatureValue) -> Any? {
		switch value.type {
		case .int64:
			return value.int64Value
		case .double:
			return value.doubleValue
		case .string:
			return value.stringValue
		default:
			return nil
		}
	}
}

class MLFNoOpValueExtractor: MLFValueExtractor {
	public func extract(_ value: MLFeatureValue) -> Any? {
		return nil
	}
}
