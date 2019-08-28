//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import UIKit

class MLFHostDevice {
	private let device: UIDevice
	
	init() {
		self.device = UIDevice.current
	}
	
	func name() -> String {
		return self.device.systemName;
	}
	
	func version() -> String {
		return self.device.systemVersion
	}
	
	func batteryLevel() -> Float {
		return self.device.batteryLevel
	}
}
