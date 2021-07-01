//
//  MLFFuture.swift
//  MLFairy
//
//  Copyright © 2019 MLFairy. All rights reserved.
//

import Foundation
import Combine

extension Publisher {
	public func sink() -> AnyCancellable {
		return self.sink(receiveCompletion: {_ in}, receiveValue: {_ in})
//		return self.sink(receiveCompletion: {Swift.print("\($0)")}, receiveValue: {Swift.print("\($0)")})
	}
}

extension Future where Failure == Error {
	static func run(on queue: DispatchQueue, _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) throws -> Void) -> Future<Output, Failure> {
		return Future<Output, Failure> { promise in
			queue.async {
				do {
					try attemptToFulfill(promise)
				} catch {
					promise(.failure(error))
				}
			}
		}
	}
	
	static func just(_ value: Output) -> Future<Output, Failure> {
		return Future<Output, Failure> { promise in
			promise(.success(value))
		}
	}
}

