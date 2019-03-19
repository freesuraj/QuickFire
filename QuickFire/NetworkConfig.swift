import Foundation

public class NetworkConfig {
	var baseUrl: String = ""
	
	public static let shared: NetworkConfig = NetworkConfig()
	
	public func set(baseUrl: String) {
		self.baseUrl = baseUrl
	}
}
