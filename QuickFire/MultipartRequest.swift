import Foundation

/// A `MultiPartData` represent a multipart file (image or a video or any other type)
public struct MultiPartData {
	
	public var fileKey: String
	public var filename: String
	public var mimeType: String
	public var data: Data
	
	public init?(fileKey: String, filename: String, largeImage: UIImage) {
		guard let data = largeImage.jpegData(compressionQuality: 0.5) else { return nil }
		self.init(fileKey: fileKey, filename: filename, data: data)
	}
	
	public init(fileKey: String, filename: String, data: Data, mimeType: String = "image/jpeg") {
		self.fileKey = fileKey
		self.filename = filename
		self.mimeType = mimeType
		self.data = data
	}
	
	/// The binary data of a raw multipart file
	public var formData: Data {
		var formData = Data()
		let dataGenerator = MultiPartHandler.DataGenerator.shared
		if let boundaryStartData = dataGenerator.initialBoundaryData,
			let dispositionData = dataGenerator.dispositionData(forFile: fileKey, filename: filename),
			let mimeData = dataGenerator.mimeData(forType: mimeType),
			let boundaryEndData = dataGenerator.finalBoundaryData {
			formData.append(boundaryStartData)
			formData.append(dispositionData)
			formData.append(mimeData)
			print("data so far", String(data: formData, encoding: .utf8) ?? "invalid")
			formData.append(dataGenerator.fileData(rawData: data))
			print("boundary end", String(data: boundaryEndData, encoding: .utf8) ?? "invalid")
			formData.append(boundaryEndData)
		}
		return formData
	}
}

/// This class prepares the binary data from a multipart object and provides a way to upload to a server
class MultiPartHandler: NSObject {
	
	struct DataGenerator {
		
		static let shared = DataGenerator()
		let boundaryKey: String
		
		private init() {
			boundaryKey = "------------\(UUID().uuidString)"
		}
		
		var initialBoundaryData: Data? {
			let encodingChars = "\r\n"
			return "--\(boundaryKey)\(encodingChars)".data(using: .utf8)
		}
		
		func dispositionData(forFile filekey: String, filename: String) -> Data? {
			return "Content-Disposition: form-data; name=\"\(filekey)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)
		}
		
		func mimeData(forType type: String) -> Data? {
			return "Content-Type: \(type)\r\n\r\n".data(using: .utf8)
		}
		
		func fileData(rawData: Data) -> Data {
			var data = rawData
			if let tail = "\r\n".data(using: .utf8) {
				data.append(tail)
			}
			return data
		}
		
		var finalBoundaryData: Data? {
			let encodingChars = "\r\n"
			return "\(encodingChars)--\(boundaryKey)--\(encodingChars)".data(using: .utf8)
		}
	}
	
	var session: URLSession?
	typealias ProgressHandler = ((Progress) -> Void)
	typealias SuccessHandler = ((Data?, URLResponse?, Error?) -> Void)
	typealias ErrorHandler = ((NetworkError) -> Void)
	
	var progressHandler: ProgressHandler
	var successHandler: SuccessHandler
	var errorHandler: ErrorHandler
	
	var uploadProgress: Progress
	var trackingQueue: DispatchQueue
	
	required init(queue: DispatchQueue = DispatchQueue.main, urlRequest: URLRequest, mediaData: Data, progress: @escaping ProgressHandler, success: @escaping SuccessHandler, failure: @escaping ErrorHandler) {
		trackingQueue = queue
		progressHandler = progress
		successHandler = success
		errorHandler = failure
		uploadProgress = Progress(totalUnitCount: 0)
		super.init()
		session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
		let task = session?.uploadTask(with: urlRequest, from: mediaData, completionHandler: successHandler)
		task?.resume()
	}
}

extension MultiPartHandler: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
	
	// Send bytes
	func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		uploadProgress.totalUnitCount = totalBytesExpectedToSend
		uploadProgress.completedUnitCount = totalBytesSent
		trackingQueue.async { self.progressHandler(self.uploadProgress) }
	}
	
	// Did complete with error
	func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
		print(error?.localizedDescription ?? "Unknown error")
		trackingQueue.async { self.errorHandler(NetworkError.custom(error?.localizedDescription ?? "Unknown error")) }
	}
}

