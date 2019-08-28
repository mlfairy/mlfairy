//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFHostDevice {
	private let device: Host
	
	init() {
		self.device = Host.current()
	}
	
	func name() -> String {
		return self.device.name ?? "";
	}
	
	func version() -> String {
		return ""
	}
	
	func batteryLevel() -> Float {
		return -1
	}
}

