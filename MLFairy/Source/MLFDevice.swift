//
//  MLDevice.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFDevice {
	private let processInfo: ProcessInfo
	private let fileManager: FileManager
	private let locale: Locale
	private let host: MLFHostDevice
	
	init(host: MLFHostDevice) {
		self.processInfo = ProcessInfo.processInfo;
		self.fileManager = FileManager.default;
		self.host = host;
		self.locale = Locale.current
	}
	
	func isSimulator() -> Bool {
		let simulator = processInfo.environment["SIMULATOR_DEVICE_NAME"]
		return simulator != nil
	}
	
	func deviceInformation() -> [String: String] {
		let deviceMemory = self.processInfo.physicalMemory
		let osVersion = self.host.version()
		let osName = self.host.name()
		let batteryLevel = self.host.batteryLevel()
		let diskSpace = self.diskSpace()
		let country = self.locale.languageCode
		let language = Locale.preferredLanguages.first
		
		var information:[String:String] = [:]
		information["memorySize"] = String(deviceMemory)
		information["osVersion"] = osVersion
		information["osName"] = osName
		information["batteryLevel"] = batteryLevel > -1 ? "" : String(batteryLevel)
		information["localeLanguage"] = language != nil ? language! : ""
		information["localeCountry"] = country != nil ? country! : ""
		information["totalSpace"] = ""
		information["totalFreeSpace"] = ""
		if let diskSpace = diskSpace, let total = diskSpace.totalSpace, let free = diskSpace.totalFreeSpace {
			information["totalSpace"] = String(total)
			information["totalFreeSpace"] = String(free)
		}
		
		return information
	}
	
	func diskSpace() -> (totalSpace:Int64?, totalFreeSpace: Int64?)? {
		let homeDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
		
		guard let directory = homeDirectory else {
			return nil;
		}
		
		do {
			let attributes = try self.fileManager.attributesOfFileSystem(forPath: directory)
			let totalSpace = attributes[.systemSize] as? Int64
			let totalFreeSpace = attributes[.systemFreeSize] as? Int64
			return (totalSpace, totalFreeSpace)
		} catch  {
			return nil
		}
	}
}
