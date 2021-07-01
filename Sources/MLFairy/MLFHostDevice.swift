//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
class MLFHostDevice {
	private let device: UIDevice
	
	init() {
		self.device = UIDevice.current
	}
	
	func name() -> String {
		return self.device.systemName
	}
	
	func version() -> String {
		return self.device.systemVersion
	}
	
	func batteryLevel() -> Float {
#if os(iOS)
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
		return self.device.name ?? "osx"
	}
	
	func version() -> String {
		return self.process.operatingSystemVersionString
	}
	
	func batteryLevel() -> Float {
		return -1
	}
}
#elseif os(watchOS)
import WatchKit
class MLFHostDevice {
	private let device: WKInterfaceDevice
	
	init() {
		self.device = WKInterfaceDevice()
	}
	
	func name() -> String {
		return self.device.systemName
	}
	
	func version() -> String {
		return self.device.systemVersion
	}
	
	func batteryLevel() -> Float {
		return self.device.batteryLevel
	}
}
#endif
