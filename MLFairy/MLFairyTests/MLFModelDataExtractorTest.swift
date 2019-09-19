//
//  MLFModelDataExtractorTest.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import XCTest
import CoreML
import MLFSupport

@testable import MLFairy

class MLFModelDataExtractorTest: XCTestCase {
	private var instance: MLFModelDataExtractor!
	
	override func setUp() {
		instance = MLFModelDataExtractor(support: MLFSupport())
	}
	
	func testModelInfoExtraction() {
		let bundle = Bundle(for: type(of: self))
		let path = bundle.url(forResource: "MultiSnacks", withExtension: nil)!
		let url = try! MLModel.compileModel(at: path)
		let model = try! MLModel(contentsOf: url)
		
		let data = instance.modelInformation(model: model)
		XCTAssertEqual(16, data.count)
		XCTAssertEqual("A model trained using CreateML", data["MLModelDescriptionKey"]!)
		XCTAssertEqual("image", data["input0_name"]!)
		XCTAssertNotNil(data["output0_name"]!)
		XCTAssertNotNil(data["output1_name"]!)
	}
	
	func testConvert() {
		let inputValue = MLFeatureValue(double: Double(1.0))
		let outputValue = MLFeatureValue(double: Double(2.0))
		
		let input = try! MLDictionaryFeatureProvider(dictionary: ["name": inputValue])
		let output = try! MLDictionaryFeatureProvider(dictionary: ["name": outputValue])
		
		let result = instance.convert(input: input, output: output)
		XCTAssertEqual(1, result.input.count)
		XCTAssertEqual(1, result.output.count)
		
		let actualInputValue = result.input["name"]
		XCTAssertEqual("double", actualInputValue!["type"])
		XCTAssertEqual("1.0", actualInputValue!["value"])
		
		let actualOutputValue = result.output["name"]
		XCTAssertEqual("double", actualOutputValue!["type"])
		XCTAssertEqual("2.0", actualOutputValue!["value"])
	}
}
