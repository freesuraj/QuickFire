import Foundation

/// Any network manager that conforms to this protocol can define how a network request can be handled
public protocol NetworkProtocol {
	func request(_ queue: DispatchQueue?, request: NetworkRequest, success: @escaping ((Any) -> Void), failure: @escaping ((NetworkError) -> Void))
}

public class NetworkManager {
	public static let shared = NetworkManager()
}

extension NetworkManager: NetworkProtocol {
	
	public func request(_ queue: DispatchQueue? = nil, request: NetworkRequest, success: @escaping ((Any) -> Void), failure: @escaping ((NetworkError) -> Void)) {
		guard let url = request.completeUrl() else {
			failure(.invalidError)
			return
		}
		var urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
		urlRequest.httpMethod = request.method.rawValue
		if request.method == .post || request.method == .put {
			urlRequest.httpBody = request.useJsonBody ? request.postJsonBody() : request.postParametersBody()
		}
		
		var headers = request.headers
		headers["Content-Type"] = request.method == .get ? "application/json" : (request.multipart == nil ? (request.useJsonBody ? "application/json" : "application/x-www-form-urlencoded") : "multipart/form-data; boundary=\(MultiPartHandler.DataGenerator.shared.boundaryKey)")
		let queueToExecute = queue ?? DispatchQueue.main
		
		// Helper function that handles success response
		func handleSuccess(data: Data?, response: URLResponse?, error: Error?) {
			guard let d = data, let json = try? JSONSerialization.jsonObject(with: d, options: []), let resp = response as? HTTPURLResponse else {
				if let d = data, let textString = String(data: d, encoding: .utf8) {
					if textString.isEmpty, request.method == .delete {
						queueToExecute.async { success(textString) }
					} else {
						queueToExecute.async { failure(NetworkError(response)) }
					}
				} else {
					var otherError: NetworkError = .invalidError
					if let errorMessage = error?.localizedDescription {
						otherError = .custom(errorMessage)
					}
					queueToExecute.async { failure(otherError) }
				}
				return
			}
			if resp.statusCode == 400 {
				queueToExecute.async { failure(.serverError(resp.statusCode)) }
			} else if 200 ... 299 ~= resp.statusCode {
				queueToExecute.async { success(json) }
			} else {
				queueToExecute.async {
					var finalError: NetworkError = .invalidError
					if let errorMessage = error?.localizedDescription {
						finalError = .custom(errorMessage)
					}
					failure(finalError)
				}
			}
		}
		
		if let multipart = request.multipart {
			headers["Content-Length"] = "\(multipart.count)"
			urlRequest.allHTTPHeaderFields = headers
			_ = MultiPartHandler(queue: queueToExecute, urlRequest: urlRequest, mediaData: multipart, progress: { progress in
				print("progress", progress.totalUnitCount, "(", progress.fractionCompleted, ")")
			}, success: handleSuccess, failure: { error in
				failure(.custom(error.localizedDescription))
			})
		} else {
			urlRequest.allHTTPHeaderFields = headers
			let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: handleSuccess)
			task.resume()
		}
		#if DEBUG
		printCurl(urlRequest: urlRequest)
		#endif
	}
	
	func printCurl(urlRequest request: URLRequest) {
		guard let method = request.httpMethod, let url = request.url else { return }
		var headerString: String = ""
		if let headers = request.allHTTPHeaderFields {
			headers.forEach {
				headerString.append("-H '\($0): \(String(describing: $1))' ")
			}
		}
		var dataString: String = ""
		if let body = request.httpBody {
			if let bodyString = String(data: body, encoding: String.Encoding.utf8) {
				dataString = "-d '\(bodyString)'"
			}
		}
		print("📶📶 curl -X \(method.uppercased()) \(headerString)\(dataString) '\(url.absoluteString)' | json 📶📶")
	}
}

extension NetworkRequest {
	
	func completeUrl() -> URL? {
		guard var fullPath = fullPath else { return nil }
		guard method == .get || method == .delete else { return URL(string: fullPath) }
		if let paramUrl = getParameterStrings() {
			fullPath.append("?\(paramUrl)")
		}
		return URL(string: fullPath)
	}
	
	func getParameterStrings() -> String? {
		var stringArray: [String] = []
		guard let params = params else { return nil }
		params.forEach { stringArray.append(parameterString(key: $0, value: $1)) }
		return stringArray.joined(separator: "&")
	}
	
	func parameterString(key: Key, value: Value) -> String {
		if let string = value as? String {
			return "\(key)=\(escape(string))"
		} else if let stringArray = value as? [String] {
			var valuesArray: [String] = []
			stringArray.forEach {
				valuesArray.append("\(key)=\(escape($0))")
			}
			return valuesArray.joined(separator: "&")
		} else {
			return "\(key)=\(value)"
		}
	}
	
	func escape(_ string: String) -> String {
		// Characters Encoding
		let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
		let subDelimitersToEncode = "!$&'()*+,;="
		var allowedCharacterSet = CharacterSet.urlQueryAllowed
		allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
		return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
	}
	
	func postParametersBody() -> Data? {
		guard let params = getParameterStrings() else { return nil }
		return params.data(using: String.Encoding.utf8)
	}
	
	func postJsonBody() -> Data? {
		guard let params = params else { return nil }
		return try? JSONSerialization.data(withJSONObject: params)
	}
}

