import Foundation

public protocol URLSessionProtocol {
    func dataTask<R: Request>(with request: R, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {
    public func dataTask<R: Request>(with request: R, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return dataTask(with: request.urlRequest, completionHandler: completionHandler)
    }
}
