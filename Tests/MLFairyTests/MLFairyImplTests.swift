//
//  MLFFairyImplTest.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import XCTest
import CoreML
import Swifter

@testable import MLFairy

class MLFairyImplTest: XCTestCase {
	private var server = HttpServer()
	private let token = "12345678"
	private let queue = DispatchQueue(label: "com.mlfairy.MLTaskTests")
	
	private var instance: MLFairyImpl!
	
	override func setUpWithError() throws {
		let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent(UUID().uuidString)
		instance = MLFairyImpl(
			fileManager: FileManager.default,
			persistenceRoot: root,
			environment: .local
		)
		
		do {
			try server.start()
		} catch {
			XCTFail("Coult not start Swifter")
		}
	}
	
	override func tearDownWithError() throws {
		server.stop()
	}

  	func testSuccessfulDownload() {
		server["/1/download"] = { _ -> HttpResponse in
			return .ok(.json([
				"downloadId": "downloadId",
				"modelId": "modelId",
				"organizationId": "organization",
				"token": self.token,
				"activeVersion": "activeVersion",
				"modelFileUrl": "http://localhost:8080/1/modelfilename",
				"hash": "YZdCsLFbjT4h0ANwzc9F8Q==",
				"algorithm": "md5"
		   ]))
		}
		
		server["/1/modelfilename"] = { _ -> HttpResponse in
			let path = Bundle.module.url(forResource: "Models/MultiSnacks", withExtension: nil)!
			let data = try! Data(contentsOf: path)
			return .ok(.data(data, contentType: "application/octet-stream"))
		}

		var model: MLModel? = nil
		var error: Error? = nil
		
		let expectation = self.expectation(description: "Get CoreML Model")
		instance.getCoreMLModel(token: self.token, options: [], queue:queue) { result in
			model = result.model!
			error = result.error
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 50000000, handler: nil)
		XCTAssertNil(error)
		XCTAssertNotNil(model)
	}
	
	func testFailedDownload() {
		server["/1/download"] = { _ -> HttpResponse in
			return .ok(.json([
				"downloadId": "downloadId",
				"modelId": "modelId",
				"organizationId": "organization",
				"token": self.token,
				"activeVersion": "activeVersion",
				"modelFileUrl": "http://localhost:8080/1/modelfilename",
				"hash": "ZdCsLFbjT4h0ANwzc9F8Q==",
				"algorithm": "md5"
		   ]))
		}
		
		server["/1/modelfilename"] = { _ -> HttpResponse in
			let path = Bundle.module.url(forResource: "Models/MultiSnacks", withExtension: nil)!
			let data = try! Data(contentsOf: path)
			return .ok(.data(data, contentType: "application/octet-stream"))
		}
		
		var model: MLModel? = nil
		var error: Error? = nil
		
		let expectation = self.expectation(description: "Get CoreML Model")
		instance.getCoreMLModel(token: self.token, options: [], queue:queue) { result in
			model = result.model ?? nil
			error = result.error
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 50000000, handler: nil)
		XCTAssertNotNil(error)
		XCTAssertNil(model)
	}
}
