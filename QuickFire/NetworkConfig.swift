import Foundation

public class NetworkConfig {
	var baseUrl: String = ""
	
	public static let shared: NetworkConfig = NetworkConfig()
	
	private init() { }
	
	public func set(baseUrl: String) {
		self.baseUrl = baseUrl
	}
	
	public let userAgent: String = {
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
}
