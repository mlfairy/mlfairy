//
//  MLLogger.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

protocol MLFLogger {
	func i(tag: String, _ message: String)
	func d(tag: String, _ message: String)
	func e(tag: String, _ message: String)
}

extension MLFLogger {
	func i(tag: String = "MLFairy", _ message: String) { return self.i(tag:tag, message) }
	func d(tag: String = "MLFairy", _ message: String) { return self.d(tag:tag, message) }
	func e(tag: String = "MLFairy", _ message: String) { return self.e(tag:tag, message) }
}

class MLFDefaultLogger: MLFLogger {
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
