//
//  MLApp.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

class MLFApp {
	public let device: MLFDevice
	public let app: Bundle
	public let sdk: Bundle
	private let log: MLFLogger

	public lazy var info: [String: String] = {
		return self.appInformation()
	}()
	
	init(logger: MLFLogger, device: MLFDevice) {
		self.device = device
		self.app = Bundle.main
		self.log = logger
		self.sdk = Bundle(for: MLFApp.self)
	}
	
	private func appInformation() -> [String: String] {
		var information = self.device.deviceInformation()
		
		let bundleVersion = self.app.object(forInfoDictionaryKey: "CFBundleVersion") as? String
		information["bundleVersion"] = bundleVersion == nil ? "0.0" : bundleVersion!
		
		let bundleIdentifier = self.app.bundleIdentifier
		information["bundleIdentifier"] = bundleIdentifier == nil ? "app" : bundleIdentifier!
		information["bundleDisplayName"] = self.bundleName()
		
		let bundleShortVersion = self.app.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
		information["bundleShortVersion"] = bundleShortVersion == nil ? "" : bundleShortVersion!
	
		let release = self.releaseType()
		information["buildType"] = release
		
		let sdkVersion = self.sdk.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
		information["sdkVersion"] = sdkVersion == nil ? "" : sdkVersion
		
		return information
	}

	private func releaseType() -> String {
		if device.isSimulator() {
			return "simulator"
		}
		
		let embeddedDictionary = self.embeddedDictionary()
		if embeddedDictionary == nil {
			return "app-store"
		}
		
		let provisionsAllDevices = embeddedDictionary!["ProvisionsAllDevices"] as? Bool
		if let _ = provisionsAllDevices {
			return "enterprise"
		}
		
		let provisionedDevices = embeddedDictionary!["ProvisionedDevices"]
		guard let _ = provisionedDevices else {
			return "app-store"
		}
		
		let entitlements = embeddedDictionary!["Entitlements"] as? [String:Any]
		guard let _ = entitlements else {
			return "ad-hoc"
		}
		
		let getAllTasks = entitlements!["get-task-allow"] as? Bool
		if let getAllTasks = getAllTasks, getAllTasks == true {
			return "dev"
		}
		
		return "ad-hoc"
	}
	
	private func embeddedDictionary() -> [String: Any]? {
		let provisioningFilePath = app.path(forResource: "embedded.mobileprovision", ofType: nil)
		guard let _ = provisioningFilePath else {
			return nil
		}
		
		do {
			let binary = try String(contentsOfFile: provisioningFilePath!, encoding: .isoLatin1)
			let scanner = Scanner(string: binary)
			if !scanner.scanUpTo("<plist", into: nil) {
				return nil
			}
			
			var plistString: NSString?
			if !scanner.scanUpTo("</plist>", into: &plistString) {
				return nil
			}
			
			let data = "\(plistString!)</plist>".data(using: .isoLatin1)
			if data == nil {
				return nil
			}
			
			let plist = try PropertyListSerialization.propertyList(from: data!, options: [], format: nil) as! [String:Any]
			
			return plist
		} catch {
			return nil
		}
	}
	
	private func bundleName() -> String {
		var bundleDisplayName = app.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
		if let bundleDisplayName = bundleDisplayName {
			return bundleDisplayName
		}
		
		bundleDisplayName = app.object(forInfoDictionaryKey: "CFBundleName") as? String
		if let bundleDisplayName = bundleDisplayName {
			return bundleDisplayName
		}
		
		bundleDisplayName = app.object(forInfoDictionaryKey: "CFBundleExecutable") as? String
		if let bundleDisplayName = bundleDisplayName {
			return bundleDisplayName
		}
		
		return ""
	}
}
