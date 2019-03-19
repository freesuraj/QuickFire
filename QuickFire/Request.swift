import Foundation

public typealias Key = String
public protocol Value {}
extension String: Value {}
extension Array: Value where Element: Value {}

/// NetworkRequest is a representation of a normal network request
public protocol NetworkRequest {
	
	var path: String { get } /// String with method and path. eg. GET /api/v1/search/
	var params: [Key: Value]? { get } /// Parameters to append to this request
	var multipart: Data? { get } /// If the request is multipart, set the data here
	var useJsonBody: Bool { get } /// Set this to true if the post request expects JSON data instead of form data
}

/// End point with path and http method
public struct APIEndpoint {
	var method: String /// Method verb: get, post, put, delete
	var path: String /// Path to append to the base url
	
	init?(from methodAndPath: String) {
		let array = methodAndPath.components(separatedBy: " ")
		guard array.count == 2 else { return nil }
		method = array[0]
		path = array[1]
	}
}

/// One of the methods of http request
public enum HttpMethod: String {
	case get, put, post, delete
}

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

public protocol Request: NetworkRequest {
	var responseType: NetworkResponse.Type { get } // Handler of the response of this network request
}

extension Request {
	/// Executes the request, and returns a Future object. A future object has three states: Pending (at the begining), Fulfill (if the request results in a response) or a Reject (if the request results in error).
	public func execute<T: NetworkResponse>() -> Future<T> {
		let future = Future<T>()
		NetworkManager.shared.request(request: self, success: { json in
			if let response = self.responseType.init(json: json) as? T {
				future.fulfill(response)
			} else {
				future.reject(NetworkError.parsingError)
			}
		}, failure: { error in
			future.reject(error)
		})
		return future
	}
}

extension NetworkRequest {
	public var apiEndpoint: APIEndpoint? {
		return APIEndpoint(from: path)
	}
	
	public var useJsonBody: Bool { return false }
	public var method: HttpMethod {
		if let name = apiEndpoint?.method.lowercased(), let method = HttpMethod(rawValue: name) {
			return method
		}
		return .get
	}
	
	public var headers: [String: String] {
		var requestHeaders: [String: String] = [:]
		requestHeaders["User-Agent"] = userAgent
		return requestHeaders
	}
	public var fullPath: String? {
		guard let path = apiEndpoint?.path else { return nil }
		return "\(NetworkConfig.shared.baseUrl)\(path)"
	}
	public var multipart: Data? { return nil }
}

let userAgent: String = {
	if let info = Bundle.main.infoDictionary,
		let executable = info[kCFBundleExecutableKey as String] as? String,
		let bundle = info[kCFBundleIdentifierKey as String] as? String,
		let appVersion = info["CFBundleShortVersionString"] as? String,
		let appBuild = info[kCFBundleVersionKey as String] as? String {
		
		let device = "iOS"
		let osNameVersion: String = {
			let version = ProcessInfo.processInfo.operatingSystemVersion
			let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
			
			let osName: String = {
				"iOS"
			}()
			
			return "\(osName) \(versionString)"
		}()
		return "\(executable)/\(appVersion) (\(device); \(osNameVersion); build:\(appBuild);)"
	}
	
	return "QuickFire/1.0.0 iOS"
}()
