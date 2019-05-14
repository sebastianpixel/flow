@testable import Environment
import Foundation
import Utils

struct URLSessionMock: URLSessionProtocol {
    func dataTask<R>(with request: R, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask where R: Request {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        let urlSession = URLSession(configuration: configuration)
        URLProtocolMock.requestHandler = { urlRequest in
            guard let url = urlRequest.url else { throw URLProtocolMock.Error.requestUrl }
            guard let response = HTTPURLResponse(url: url,
                                                 statusCode: 200,
                                                 httpVersion: nil,
                                                 headerFields: nil) else { throw URLProtocolMock.Error.response }
            return (response, R.Response.fixture.encoded)
        }
        return urlSession.dataTask(with: request.urlRequest, completionHandler: completionHandler)
    }
}
