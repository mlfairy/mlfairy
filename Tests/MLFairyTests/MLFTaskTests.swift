//
//  MLFTaskTests.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

import XCTest
//import OHHTTPStubs
import Combine
import CoreML

@testable import MLFairy

class MLTaskTests: XCTestCase {
	private let log: MLFLogger = MLFLoggerStub()
	private let queue = DispatchQueue(label: "com.mlfairy.MLTaskTests")
	private let token = "12345678"
	
	private var persistence: MLFPersistenceStub!
	private var task: MLFDownloadTask!
	
	private var subscriptions = [AnyCancellable]()
	
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
		let result = self.checkForFailure(task.compileModel(URL(string:"https://example.com")!, metadata))
		XCTAssertEqual(result.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.compilationFailed(message: \"Failed to compile model for token 12345678\", reason: Error Domain=com.apple.CoreML Code=3 \"Error reading protobuf spec. validator error: unable to open file for read\" UserInfo={NSLocalizedDescription=Error reading protobuf spec. validator error: unable to open file for read})))")
	}
	
	func testCompilationSucceeds() {
		let path = Bundle.module.url(forResource: "Models/MultiSnacks", withExtension: nil)!
		let metadata = self.makeMetadata(token: token)
		let value = self.checkForSuccess(task.compileModel(path, metadata))
		XCTAssertNotNil(value.compiledModelUrl)
		XCTAssertNotNil(value.model)
	}
	/*
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

		let metadata = self.checkForSuccess(task.downloadMetadata(token, info: [:], fallback: nil, on: queue))
		
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

		let result = self.checkForFailure(task.downloadMetadata(token, info: [:], fallback: nil, on: queue))
		XCTAssertEqual(result.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.noDownloadAvailable))")
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

		let result = self.checkForFailure(task.downloadMetadata(token, info: [:], fallback: nil, on: queue))
		XCTAssertEqual(result.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.noDownloadAvailable))")
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

		let metadata = self.checkForSuccess(task.downloadMetadata(token, info: [:], fallback: fallback, on: queue))
		
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

		let result = self.checkForFailure(task.downloadMetadata(token, info: [:], fallback: nil, on: queue))
		XCTAssertEqual(result.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.downloadFailed(message: \"Failed to download model metadata\", reason: MLFairy.MLFError.networkError(response: \"bad request\"))))")
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

		let url = self.checkForSuccess(task.downloadModel(metadata, to: destination, on: queue))
		XCTAssertEqual(destination, url)
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

		let _ = self.checkForFailure(task.downloadModel(metadata, to: destination, on: queue))
//		XCTAssertEqual(error.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.downloadFailed(message: \"Failed to download model for \", reason: Alamofire.AFError.sessionTaskFailed(error: Error Domain=test Code=42 \"(null)\" UserInfo={_NSURLErrorRelatedURLSessionTaskErrorKey=(\"LocalDownloadTask <C584EB5D-9C2E-45F4-A1AF-8EFD1EB7EF34>.<1>\"), _NSURLErrorFailingURLSessionTaskErrorKey=LocalDownloadTask <C584EB5D-9C2E-45F4-A1AF-8EFD1EB7EF34>.<1>}))))")
	}
	*/
	func testDownloadModelSucceedsIfModelExistsSkippingChecksum() {
		persistence.existsCallback = {
			return true
		}

		let destination = makeTemporaryFile()
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename"
		)

		let url = self.checkForSuccess(task.downloadModel(metadata, to: destination, on: queue))
		XCTAssertEqual(destination, url)
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

		let url = self.checkForSuccess(task.downloadModel(metadata, to: destination, on: queue))
		XCTAssertEqual(destination, url)
	}
	
	func testDownloadModelSucceedsIfModelExistsAndPassesChecksum() {
		persistence.existsCallback = {
			return true
		}

		let destination = Bundle.module.url(forResource: "Models/MultiSnacks", withExtension: nil)!
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename",
			hash: "YZdCsLFbjT4h0ANwzc9F8Q==",
			algorithm: "md5"
		)

		let url = self.checkForSuccess(task.downloadModel(metadata, to: destination, on: queue))
		XCTAssertEqual(destination, url)
	}
	
	func testDownloadModelSucceedsIfModelExistsAndFailsChecksum() {
		persistence.existsCallback = {
			return true
		}

		let destination = Bundle.module.url(forResource: "Models/MultiSnacks", withExtension: nil)!
		let metadata = makeMetadata(
			modelFileUrl: "https://api.mlfairy.com/modelfilename",
			hash: "unknown",
			algorithm: "md5"
		)

		let error = self.checkForFailure(task.downloadModel(metadata, to: destination, on: queue))
		XCTAssertEqual(error.debugDescription, "Optional(Combine.Subscribers.Completion<Swift.Error>.failure(MLFairy.MLFError.failedChecksum))")
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
	
	private func checkForSuccess<Output, Failure>(
		_ future: Future<Output, Failure>,
		description: String = #function
	) -> Output {
		let expectation = self.expectation(description: description)
		var output: Output? = nil
		future.sink(
			receiveCompletion: { _ in },
			receiveValue: {
				output = $0
				expectation.fulfill()
			}
		)
		.store(in: &subscriptions)
		waitForExpectations(timeout: 10, handler: nil)
		XCTAssertNotNil(output)
		
		return output!
	}
	
	private func checkForFailure<Output, Error>(
		_ future: Future<Output, Error>,
		description: String = #function
	) -> Subscribers.Completion<Error>? {
		let expectation = self.expectation(description: description)
		var result: Subscribers.Completion<Error>? = nil
		future.sink(
			receiveCompletion: {
				result = $0
				expectation.fulfill()
			},
			receiveValue: { _ in expectation.isInverted = true }
		)
		.store(in: &subscriptions)

		waitForExpectations(timeout: 10, handler: nil)
		XCTAssertNotNil(result)
		
		return result
	}
}
