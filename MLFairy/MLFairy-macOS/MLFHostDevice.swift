//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFHostDevice {
	private let device: Host
	private let process: ProcessInfo
	
	init() {
		self.process = ProcessInfo.processInfo
		self.device = Host.current()
	}
	
	func name() -> String {
		return self.device.name ?? "";
	}
	
	func version() -> String {
		return self.process.operatingSystemVersionString
	}
	
	func batteryLevel() -> Float {
		return -1
	}
}

