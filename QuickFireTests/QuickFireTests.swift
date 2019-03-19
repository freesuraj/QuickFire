//
//  QuickFireTests.swift
//  QuickFireTests
//
//  Created by Suraj Pathak on 19/3/19.
//  Copyright © 2019 kakhara.com. All rights reserved.
//

import XCTest
@testable import QuickFire

extension Request {
	public var headers: [String: String] { return ["referer": "example.com"] }
}

public struct ProductDetail: Response {
	
	var name: String
	
	public init?(json: Any) {
		guard let dict = json as? [String: Any], let title = dict["title"] as? String else { return nil }
		name = title
	}
}

public struct ProductDetailRequest: Request {
	
	public var path: String {
		return "GET /api/v1/products/\(productId)/"
	}
	
	let productId: String
	public let responseType: Response.Type = ProductDetail.self
	
	public init(productId: String) {
		self.productId = productId
	}
}

class QuickFireTests: XCTestCase {

    override func setUp() {
		NetworkConfig.shared.baseUrl = "https://www.example.com"
    }

    override func tearDown() {
    }

    func testExample() {
		func onDetail(_ response: ProductDetail) {
			print("product is \(response.name)")
		}
		
		func onError(_ error: Error) {
			print("error: \(error.localizedDescription)")
		}
		ProductDetailRequest(productId: "1111").execute().then(onDetail).catch(onError)
    }

}
