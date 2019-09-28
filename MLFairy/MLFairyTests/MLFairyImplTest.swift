//
//  MLFFairyImplTest.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import XCTest
import OHHTTPStubs
import CoreML

@testable import MLFairy

class MLFairyImplTest: XCTestCase {
	private let token = "12345678"
	private let queue = DispatchQueue(label: "com.mlfairy.MLTaskTests")
	
	private var instance: MLFairyImpl!
	
	override func setUp() {
		let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent(UUID().uuidString)
		instance = MLFairyImpl(
			fileManager: FileManager.default,
			persistenceRoot: root
		)
	}
	
  	func testSuccessfulDownload() {
		var callCounter = 0
		stub(condition: isHost("api.mlfairy.com")) { _ in
			callCounter += 1
			if callCounter == 1 {
				let obj = [
					"downloadId": "downloadId",
					"modelId": "modelId",
					"organizationId": "organization",
					"token": self.token,
					"activeVersion": "activeVersion",
					"modelFileUrl": "https://api.mlfairy.com/modelfilename",
					"hash": "YZdCsLFbjT4h0ANwzc9F8Q==",
					"algorithm": "md5"
				]
				return OHHTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
			} else if callCounter == 2 {
				let bundle = Bundle(for: type(of: self))
				let path = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
				return OHHTTPStubsResponse(fileURL: path, statusCode: 200, headers: nil)
			} else {
				let error = NSError(domain: "test", code: 42, userInfo: [:])
				return OHHTTPStubsResponse(error: error)
			}
		}
		
		var model: MLModel? = nil
		var error: Error? = nil
		
		let expectation = self.expectation(description: "Get CoreML Model")
		instance.getCoreMLModel(token: self.token, queue:queue) { result in
			model = result.model!
			error = result.error
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 50000000, handler: nil)
		XCTAssertNil(error)
		XCTAssertNotNil(model)
	}
	
	func testFailedDownload() {
		var callCounter = 0
		stub(condition: isHost("api.mlfairy.com")) { _ in
			callCounter += 1
			if callCounter == 1 {
				let obj = [
					"downloadId": "downloadId",
					"modelId": "modelId",
					"organizationId": "organization",
					"token": self.token,
					"activeVersion": "activeVersion",
					"modelFileUrl": "https://api.mlfairy.com/modelfilename",
					"hash": "ZdCsLFbjT4h0ANwzc9F8Q==",
					"algorithm": "md5"
				]
				return OHHTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
			} else if callCounter == 2 {
				let bundle = Bundle(for: type(of: self))
				let path = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
				return OHHTTPStubsResponse(fileURL: path, statusCode: 200, headers: nil)
			} else {
				let error = NSError(domain: "test", code: 42, userInfo: [:])
				return OHHTTPStubsResponse(error: error)
			}
		}
		
		var model: MLModel? = nil
		var error: Error? = nil
		
		let expectation = self.expectation(description: "Get CoreML Model")
		instance.getCoreMLModel(token: self.token, queue:queue) { result in
			model = result.model ?? nil
			error = result.error
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 50000000, handler: nil)
		XCTAssertNotNil(error)
		XCTAssertNil(model)
	}
}
