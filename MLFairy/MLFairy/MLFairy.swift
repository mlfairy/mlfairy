//
//  MLFairy.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import CoreML

public class MLFairy {
	private static let instance = MLFairyImpl()
	
	public static func getCoreMLModel(_ modelToken: String, callback: (MLModel?, Error?) -> Void) {
		MLFairy.instance.getCoreMLModel(modelToken, callback: callback)
	}
	
	public static func setUserId(_ userId: String, forModel modelToken: String) {
		
	}
}
