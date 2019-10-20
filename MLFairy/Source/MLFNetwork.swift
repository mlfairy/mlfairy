//
//  MLFNetwork.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Alamofire
import Promises
import MLFSupport

class MLFNetwork {
	private static let BASE_URL = "https://api.mlfairy.com/1"
	private static let DOWNLOAD_URL = "\(BASE_URL)/download"
	private static let ENCRYPTION_URL = "\(BASE_URL)/encryption"
	private static let EVENT_URL = "\(BASE_URL)/event"
	private static let DOWNLOAD_OPTIONS: DownloadRequest.Options = [
		.createIntermediateDirectories, .removePreviousFile
	]
	
	public static let mlUserAgent: HTTPHeader = {
		let userAgent: String = {
			if let info = Bundle.main.infoDictionary {
				let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
				let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
				let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
				let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"
				
				let osNameVersion: String = {
					let version = ProcessInfo.processInfo.operatingSystemVersion
					let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
					
					let osName: String = {
						#if os(iOS)
						return "iOS"
						#elseif os(watchOS)
						return "watchOS"
						#elseif os(tvOS)
						return "tvOS"
						#elseif os(macOS)
						return "macOS"
						#elseif os(Linux)
						return "Linux"
						#else
						return "Unknown"
						#endif
					}()
					
					return "\(osName) \(versionString)"
				}()
				
				let mlFairySupport: String = {
					guard
						let afInfo = Bundle(for: MLFSupport.self).infoDictionary,
						let build = afInfo["CFBundleShortVersionString"]
						else { return "MLFSupport/Unknown" }
					
					return "MLFSupport/\(build)"
				}()
				
				let mlFairyVersion: String = {
					guard
						let afInfo = Bundle(for: MLFNetwork.self).infoDictionary,
						let build = afInfo["CFBundleShortVersionString"]
						else { return "MLFairy/Unknown" }
					
					return "MLFairy/\(build)"
				}()
				
				return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(mlFairySupport) \(mlFairyVersion)"
			}
			
			return "MLFairy"
		}()
		
		return .userAgent(userAgent)
	}()
	
	static let `default`: HTTPHeaders = [
		.defaultAcceptEncoding,
		.defaultAcceptLanguage,
		MLFNetwork.mlUserAgent
	]
	
	private let session: Session = Session(startRequestsImmediately:false)
	
	static func remapToMLFErrorIfNecessary(_ error: Error, data: Data?) -> Error {
		if case AFError.responseSerializationFailed(_) = error {
			if let data = data, let mlfError = MLFNetwork.decode(of: MLFErrorResponse.self, data) {
				return MLFError.networkError(response: mlfError.message)
			}
		}
		
		return error
	}
	
	static func decode<T: Decodable>(
		of type: T.Type = T.self,
		_ data: Data,
		decoder: DataDecoder = JSONDecoder()
	) -> T? {
		return try? decoder.decode(type.self, from: data)
	}
	
	func metadata(_ body: Parameters) -> DataRequest {
		return self.session.request(
			MLFNetwork.DOWNLOAD_URL,
			method: .post,
			parameters: body,
			encoding: JSONEncoding.default,
			headers: MLFNetwork.default
		)
	}
	
	func encryption(_ body: Parameters) -> DataRequest {
		return self.session.request(
			MLFNetwork.ENCRYPTION_URL,
			method: .post,
			parameters: body,
			encoding: JSONEncoding.default,
			headers: MLFNetwork.default
		)
	}
	
	func download(_ url: String, into destination: URL) -> DownloadRequest {
		let destination: DownloadRequest.Destination = { _, _ in (destination, MLFNetwork.DOWNLOAD_OPTIONS) }
		return self.session.download(url, to: destination)
	}
	
	func event(_ event: Parameters) -> DataRequest {
		return self.session.request(
			MLFNetwork.EVENT_URL,
			method: .post,
			parameters: event,
			encoding: JSONEncoding.default,
			headers: MLFNetwork.default
		)
	}
}
