//
//  MLFModelDataExtractorTest.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import XCTest
import CoreML

@testable import MLFairy

class MLFModelDataExtractorTest: XCTestCase {
	private var instance: MLFModelDataExtractor!
	
	override func setUp() {
		instance = MLFModelDataExtractor()
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
		
		let input = try! MLDictionaryFeatureProvider(dictionary: ["input": inputValue])
		let output = try! MLDictionaryFeatureProvider(dictionary: ["output ": outputValue])
		
		let result = instance.convert(input: input, output: output)
		
	}
}
