//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
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
#if os(iOS) || os(watchOS)
		return self.device.batteryLevel
#elseif os(tvOS)
		return -1
#endif
	}
}
	
#elseif os(OSX)
class MLFHostDevice {
	private let device: Host
	private let process: ProcessInfo
	
	init() {
		self.process = ProcessInfo.processInfo
		self.device = Host.current()
	}
	
	func name() -> String {
		return self.device.name ?? "osx";
	}
	
	func version() -> String {
		return self.process.operatingSystemVersionString
	}
	
	func batteryLevel() -> Float {
		return -1
	}
}
#endif
