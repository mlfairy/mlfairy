//
//  MLFTaskTests.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

import XCTest
import OHHTTPStubs

@testable import MLFairy
@testable import Promises

class MLTaskTests: XCTestCase {
	private let log: MLFLogger = MLFLoggerStub()
	private let queue = DispatchQueue(label: "com.mlfairy.MLTaskTests")
	private let token = "12345678"
	
	private var persistence: MLFPersistenceStub!
	private var task: MLFDownloadTask!
	
	override func setUp() {
		persistence = MLFPersistenceStub(log: log)
		task = MLFDownloadTask(
			network: MLFNetwork(),
			persistence: persistence,
			log: log
		)
	}
	
	func testCompilationFailsOnNilUrl() {
		let metadata = self.makeMetadata(token: token)
		let promise = task.compileModel(URL(string:"https://example.com")!, metadata, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func testCompilationSucceeds() {
		let bundle = Bundle(for: type(of: self))
		let path = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
		
		let metadata = self.makeMetadata(token: token)
		let promise = task.compileModel(path, metadata, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value!)
	}
	
	func testDownloadMetadataSucceeds() {
		let downloadId = "download-id"
		let modelId = "model-id"
		let organizationId = "organizationId"
		let activeVersion = "fallback-activeVersion"
		let modelFileUrl = "fallback-modelFileUrl"
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			let obj = [
				"downloadId": downloadId,
				"modelId": modelId,
				"organizationId": organizationId,
				"token": self.token,
				"activeVersion": activeVersion,
				"modelFileUrl": modelFileUrl
			]
			return OHHTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
		}
		
		let promise = task.downloadMetadata(token, info: [:], fallback: nil, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value!)
		
		let metadata = promise.value!
		XCTAssertEqual(downloadId, metadata.downloadId)
		XCTAssertEqual(modelId, metadata.modelId)
		XCTAssertEqual(organizationId, metadata.organizationId)
		XCTAssertEqual(token, metadata.token)
	}
	
	func testDownloadMetadataFailsWithoutActiveVersion() {
		let downloadId = "download-id"
		let modelId = "model-id"
		let organizationId = "organizationId"
		let modelFileUrl = "fallback-modelFileUrl"
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			let obj = [
				"downloadId": downloadId,
				"modelId": modelId,
				"organizationId": organizationId,
				"token": self.token,
				"modelFileUrl": modelFileUrl
			]
			return OHHTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
		}
		
		let promise = task.downloadMetadata(token, info: [:], fallback: nil, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func testDownloadMetadataFailsWithoutModelFileUrl() {
		let downloadId = "download-id"
		let modelId = "model-id"
		let organizationId = "organizationId"
		let activeVersion = "activeVersion"
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			let obj = [
				"downloadId": downloadId,
				"modelId": modelId,
				"organizationId": organizationId,
				"token": self.token,
				"activeVersion": activeVersion
			]
			return OHHTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
		}
		
		let promise = task.downloadMetadata(token, info: [:], fallback: nil, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func testDownloadMetadataReturnsFallback() {
		let downloadId = "fallback-download-id"
		let modelId = "fallback-model-id"
		let organizationId = "fallback-organizationId"
		let activeVersion = "fallback-activeVersion"
		let modelFileUrl = "fallback-modelFileUrl"
		let fallback = MLFDownloadMetadata(downloadId: downloadId, modelId: modelId, organizationId: organizationId, token: token, activeVersion: activeVersion, modelFileUrl: modelFileUrl, hash: nil, digest: nil, algorithm: nil, size: -1)
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			return OHHTTPStubsResponse(data: Data(), statusCode: 400, headers: nil)
		}
		
		let promise = task.downloadMetadata(token, info: [:], fallback: fallback, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value!)
		
		let metadata = promise.value!
		XCTAssertEqual(downloadId, metadata.downloadId)
		XCTAssertEqual(modelId, metadata.modelId)
		XCTAssertEqual(organizationId, metadata.organizationId)
		XCTAssertEqual(token, metadata.token)
	}
	
	func testDownloadMetadataFailsWithoutFallback() {
		stub(condition: isHost("api.mlfairy.com")) { _ in
			let obj = ["message": "bad request"]
			return OHHTTPStubsResponse(jsonObject: obj, statusCode: 400, headers: nil)
		}
		
		let promise = task.downloadMetadata(token, info: [:], fallback: nil, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func testDownloadModelSucceedsIfModelDoesntExistsSkippingChecksum() {
		persistence.existsCallback = {
			return false
		}
		
		let bundle = Bundle(for: type(of: self))
		let path = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
		let destination = makeTemporaryFile()
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename"
		)
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			return OHHTTPStubsResponse(fileURL: path, statusCode: 200, headers: nil)
		}
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value)
		XCTAssertEqual(destination, promise.value)
	}
	
	func testDownloadModelFailsIfDownloadFails() {
		persistence.existsCallback = {
			return false
		}
		
		let destination = makeTemporaryFile()
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename"
		)
		
		stub(condition: isHost("api.mlfairy.com")) { _ in
			let error = NSError(domain: "test", code: 42, userInfo: [:])
			return OHHTTPStubsResponse(error: error)
		}
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func testDownloadModelSucceedsIfModelExistsSkippingChecksum() {
		persistence.existsCallback = {
			return true
		}
		
		let destination = makeTemporaryFile()
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename"
		)
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value)
		XCTAssertEqual(destination, promise.value)
	}
	
	func testDownloadModelSucceedsIfModelExistsUnknownChecksumAlgorithm() {
		persistence.existsCallback = {
			return true
		}
		
		let destination = makeTemporaryFile()
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename",
			hash: "unknown",
			algorithm: "unknown"
		)
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value)
		XCTAssertEqual(destination, promise.value)
	}
	
	func testDownloadModelSucceedsIfModelExistsAndPassesChecksum() {
		persistence.existsCallback = {
			return true
		}
		
		let bundle = Bundle(for: type(of: self))
		let destination = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
		
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename",
			hash: "YZdCsLFbjT4h0ANwzc9F8Q==",
			algorithm: "md5"
		)
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNil(promise.error)
		XCTAssertTrue(promise.isFulfilled)
		XCTAssertNotNil(promise.value)
		XCTAssertEqual(destination, promise.value)
	}
	
	func testDownloadModelSucceedsIfModelExistsAndFailsChecksum() {
		persistence.existsCallback = {
			return true
		}
		
		let bundle = Bundle(for: type(of: self))
		let destination = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
		
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename",
			hash: "unknown",
			algorithm: "md5"
		)
		
		let promise = task.downloadModel(metadata, to: destination, on: queue)
		
		XCTAssert(waitForPromises(timeout: 10))
		XCTAssertNotNil(promise.error)
		XCTAssertFalse(promise.isFulfilled)
		XCTAssertNil(promise.value)
	}
	
	func makeTemporaryFile(
		directory: StaticString = #function,
		filename: String = UUID().uuidString
	) -> URL {
		let file = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent("\(directory)")
			.appendingPathComponent(filename)
		try! FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
		
		return file
	}
	
	private func makeMetadata(
		downloadId: String = "",
		modelId: String = "",
		organizationId: String = "",
		token: String = "",
		activeVersion: String? = nil,
		modelFileUrl: String? = nil,
		hash: String? = nil,
		digest: String? = nil,
		algorithm: String? = nil,
		size: Int? = -1
	) -> MLFDownloadMetadata {
		return MLFDownloadMetadata(
			downloadId: downloadId,
			modelId: modelId,
			organizationId: organizationId,
			token: token,
			activeVersion: activeVersion,
			modelFileUrl: modelFileUrl,
			hash: hash,
			digest: digest,
			algorithm: algorithm,
			size: size
		)
	}
}
