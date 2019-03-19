import Foundation

public class Future<Value> {
	
	enum State {
		case pending, rejected, fulfilled
	}
	
	private var state: State = .pending
	
	private lazy var successCallbacks = [(Value) -> Void]()
	private lazy var failCallbacks = [(Error) -> Void]()
	
	private var success: Value? {
		didSet {
			if let success = success {
				report(success)
			}
		}
	}
	
	private var error: Error? {
		didSet {
			if let error = error {
				report(error)
			}
		}
	}
	
	@discardableResult
	public func then(_ callback: @escaping ((Value) -> Void)) -> Future<Value> {
		successCallbacks.append(callback)
		return self
	}
	
	@discardableResult
	public func `catch`(_ callback: @escaping ((Error) -> Void)) -> Future<Value> {
		failCallbacks.append(callback)
		return self
	}
	
	func fulfill(_ value: Value) {
		guard state == .pending else { return }
		success = value
		state = .fulfilled
	}
	
	func reject(_ error: Error) {
		guard state == .pending else { return }
		self.error = error
		state = .rejected
	}
	
	private func report(_ result: Value) {
		for callback in successCallbacks {
			callback(result)
		}
	}
	
	private func report(_ error: Error) {
		for callback in failCallbacks {
			callback(error)
		}
	}
}
