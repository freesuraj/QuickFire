import Foundation

public typealias Key = String
public protocol Value {}
extension String: Value {}
extension Array: Value where Element: Value {}

/// Request is a representation of a normal network request
public protocol Request {
	
	var path: String { get } /// String with method and path. eg. GET /api/v1/search/
	var headers: [String: String] { get } /// Specific headers for this request
	var params: [Key: Value]? { get } /// Parameters to append to this request
	var multipart: Data? { get } /// If the request is multipart, set the data here
	var useJsonBody: Bool { get } /// Set this to true if the post request expects JSON data instead of form data
	var responseType: Response.Type { get } // Handler of the response of this network request
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

extension Request {
	/// Executes the request, and returns a Future object. A future object has three states: Pending (at the begining), Fulfill (if the request results in a response) or a Reject (if the request results in error).
	public func execute<T: Response>() -> Future<T> {
		let future = Future<T>()
		let networkManager = NetworkManager()
		networkManager.request(request: self, success: { json in
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

extension Request {
	public var apiEndpoint: APIEndpoint? {
		return APIEndpoint(from: path)
	}
	public var params: [Key: Value]? { return nil } // Default implementation
	public var useJsonBody: Bool { return false }   // Default implementation
	public var method: HttpMethod {
		if let name = apiEndpoint?.method.lowercased(), let method = HttpMethod(rawValue: name) {
			return method
		}
		return .get
	}
	
	public var fullPath: String? {
		guard let path = apiEndpoint?.path else { return nil }
		return "\(NetworkConfig.shared.baseUrl)\(path)"
	}
	public var multipart: Data? { return nil }
}
