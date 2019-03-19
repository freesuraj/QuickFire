### QuickFire

Normal Network Library requirement for iOS apps generally boils down to following simple steps:

- Making a Request.
- Fire the Request asynchronously and receive either a successful data or an error.

Since the advent of `URLSessionDataTask` in swift, using custom network libraries like Alamofire are no longer necessary. It's easy enough to write a simple wrapper to create a `URLSessionDataTask` and observe the response in the callback.

With that said, we still need to write our custom data handler to decide which data is useful and which data is not useful.

Let's see an example:

We have a `User Login` api at this end point:

`https://example.com/user/login`

We want to receive a `User` Object when I execute the api with parameters `user_name` and `password`.


**QuickFire** is a wrapper that takes away all the steps that happens in between the request and response and let's you focus on defining request and response ONLY.

```swift
struct UserLoginRequest: Request {
    var path: String = "POST /user/login"
    var params: [Key: Value] {
        return ["user_name": userName, "password": password]
    }
    
    private var userName: String
    private var password: String
    
    init(userName: String, password: String) {
    	self.userName = userName
        self.password = password
    }
}


struct User: Response {
    var fullName: String
    var badge: String
    var balance: Double
}

UserLoginRequest(userName: "xxx", password: "xxxx").execute().then(User).catch(Error)

```

Another example:

```swift
import QuickFire

extension Request {
    public var headers: [String: String] { return ["referer": "example.com"] } // Common headers for all requests
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

class Example {

    func testExample() {
        func onDetail(_ response: ProductDetail) {
            print("product is \(response.name)")
        }

        func onError(_ error: Error) {
            print("error: \(error.localizedDescription)")
        }

    NetworkConfig.shared.baseUrl = "https://www.example.com"
    ProductDetailRequest(productId: "1111").execute().then(onDetail).catch(onError)
    }

}
```