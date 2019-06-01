import Fixture
import Foundation
import Model
import Utils

public protocol Request {
    associatedtype Response: Codable, Mockable

    var method: HTTPMethod { get }
    var path: String { get }
    var host: String? { get }
    var queryItems: [URLQueryItem] { get }
    var httpBody: Data? { get }
}

extension Request {
    public func request() -> Future<Result<Response, Swift.Error>> {
        return ApiClient.request(self)
    }

    public func awaitResponseWithDebugPrinting() -> Response? {
        switch request().await() {
        case let .success(success):
            return success
        case let .failure(failure):
            if Env.current.debug {
                Env.current.shell.write("\(failure)")
            } else if case let ApiClientError.status(_, error?) = failure {
                Env.current.shell.write(error)
            }
            return nil
        }
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        for (field, value) in headerFields {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let httpBody = httpBody {
            request.httpBody = httpBody
        }

        return request
    }

    private var url: URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = path
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            fatalError("Could not generate Request URL.")
        }

        return url
    }

    private var headerFields: [String: String] {
        let username = Env.current.login.username
        let password = Env.current.login.password
        guard let loginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() else {
            fatalError("Could not generate base64EncodedString from login.")
        }

        let headers = [
            "Authorization": "Basic \(loginString)",
            "Accept": "application/json",
            "Content-Type": "application/json; charset=utf-8",
            "X-Atlassian-Token": "no-check",
            "accept-language": "en"
        ]

        return headers
    }
}
