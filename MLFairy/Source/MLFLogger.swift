//
//  MLLogger.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFLogger {
	private let debugEnabled: Bool
	
	init() {
		self.debugEnabled = ProcessInfo.processInfo.arguments.contains("-MLFEnableDebug")
	}
	
	func i(tag: String = "MLFairy", _ message: String) {
		print("[\(tag)]: \(message)")
	}
	
	func d(tag: String = "MLFairy", _ message: String) {
		if debugEnabled {
			print("[\(tag):DEBUG]: \(message)")
		}
	}
	
	func e(tag: String = "MLFairy", _ message: String) {
		print("[\(tag):ERROR]: \(message)")
	}
}
