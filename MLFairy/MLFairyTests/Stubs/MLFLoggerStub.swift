//
//  MLFLoggerStub.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
@testable import MLFairy

class MLFLoggerStub: MLFLogger {
	func i(tag: String, _ message: String) {}
	func d(tag: String, _ message: String) {}
	func e(tag: String, _ message: String) {}
}
