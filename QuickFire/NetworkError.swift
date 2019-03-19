//
//  NetworkError.swift
//  QuickFire
//
//  Created by Suraj Pathak on 20/3/19.
//  Copyright © 2019 kakhara.com. All rights reserved.
//

import Foundation

/// A list of possible network related errors
public enum NetworkError: Error, LocalizedError {
	case invalidError
	case serverError(Int)
	case parsingError
	case userAbandoned
	case custom(String)
	
	public init(_ response: URLResponse?) {
		guard let resp = response as? HTTPURLResponse else {
			self = .invalidError
			return
		}
		if 200 ... 299 ~= resp.statusCode {
			self = .parsingError
		}
		self = .serverError(resp.statusCode)
	}
	
	public var errorDescription: String? {
		switch self {
		case .invalidError: return "Invalid Error"
		case let .serverError(statusCode): return "Server Error \(statusCode)"
		case .parsingError: return "Parsing Error"
		case .userAbandoned: return "User Abandoned Request Error"
		case let .custom(text): return text
		}
	}
	
	public var hasReadableMessage: Bool {
		switch self {
		case .custom, .userAbandoned: return true
		default: return false
		}
	}
	
	public var failureReason: String? {
		return errorDescription
	}
	
	public var recoverySuggestion: String? {
		return errorDescription
	}
}
