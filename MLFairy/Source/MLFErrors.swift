//
//  MLFErrors.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

public enum MLFError: Error {
	case compilationFailed(message: String, reason: Error)
	case checksumError(error: Error)
	case downloadFailed(message: String, reason: Error)
	case failedChecksum
	case networkError(response: String)
	case noDownloadAvailable
}

public enum MLFModelError: Error {
	case notSupported
}
