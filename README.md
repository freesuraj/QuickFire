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

```
struct User {
	var fullname: String
	var badge: String
	var balance: Double
}
```

**QuickFire** is a wrapper that takes away all the steps that happens in between the request and response and let's you focus on defining request and response ONLY.

```
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