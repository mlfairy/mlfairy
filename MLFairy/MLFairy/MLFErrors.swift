//
//  MLFErrors.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation

public enum MLFError: Error {
	case networkError(response: String)
	case noDownloadAvailable
	case downloadFailed(message: String, reason: Error)
	case compilationFailed(message: String, reason: Error)
}
