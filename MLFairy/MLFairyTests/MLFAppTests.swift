//
//  MLFAppTests.swift
//  MLFairyTests
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import XCTest

@testable import MLFairy

class MLFAppTests: XCTestCase {
    func testParsingEmbeddedMobileProvisioning() {
		let app = MLFApp(
			logger: MLFLoggerStub(),
			device: MLFDevice(host: MLFHostDevice())
		)
		let bundle = Bundle(for: type(of: self))
		let path = bundle.path(forResource: "embedded.mp", ofType: nil)
		let plist = app.readPlist(path!)
		XCTAssertNotNil(plist)
		
		let version = plist!["Version"] as! Int
		XCTAssertEqual(1, version)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
