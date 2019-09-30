import Foundation
import Model
import Utils

public enum ApiClientError: Error {
    case
        noResponse,
        captchaChallenge,
        status(Int, BitbucketError?),
        noData,
        request(Swift.Error),
        decoding(Swift.Error)
}

public struct BitbucketError: Decodable {
    public let errors: [BitbucketServiceException]

    public var messagesConcatenated: String {
        return errors.reduce(into: "", { $0 += " \($1.message)" }).trimmingCharacters(in: .whitespaces)
    }
}

public struct BitbucketServiceException: Decodable {
    public let message: String
}

public struct ApiClient {
    public static func request<R: Request>(_ request: R) -> Future<Result<R.Response, Swift.Error>> {
        debugPrint(request.urlRequest)

        return Future<Result<R.Response, Swift.Error>> { resolver in

            Env.current.urlSession.dataTask(with: request) { data, urlResponse, error in

                debugPrint(data, urlResponse)

                let response = Result<R.Response, Swift.Error> {
                    if let error = error {
                        Env.current.shell.write("\(error)")
                        throw ApiClientError.request(error)
                    }

                    guard let urlResponse = urlResponse as? HTTPURLResponse else {
                        throw ApiClientError.noResponse
                    }

                    if urlResponse.allHeaderFields.values.contains(where: { ($0 as? String)?.contains("CAPTCHA_CHALLENGE") ?? false }) {
                        Env.current.shell.write("""
                        There have been too many failed attempts logging in to JIRA.
                        Please use the browser to log in to do the captcha challenge. (It's a JIRA thing…)
                        """)
                        throw ApiClientError.captchaChallenge
                    }

                    guard 200 ..< 300 ~= urlResponse.statusCode else {
                        throw ApiClientError.status(urlResponse.statusCode, try data?.decoded())
                    }

                    guard let data = data else {
                        throw ApiClientError.noData
                    }

                    if data.isEmpty,
                        let empty = Empty() as? R.Response {
                        return empty
                    }

                    do {
                        return try data.decoded()
                    } catch {
                        throw ApiClientError.decoding(error)
                    }
                }

                debugPrint { "\(response)" }
                resolver(response)
            }.resume()
        }
    }

    private static func debugPrint(_ request: URLRequest) {
        debugPrint {
            var requestDump = ""
            dump(request, to: &requestDump)

            return """

            Request:
            \(requestDump)

            Header:
            \(request.allHTTPHeaderFields as Any)

            Body:
            \(request.httpBody.flatMap { String(data: $0, encoding: .utf8) } as Any)
            """
        }
    }

    private static func debugPrint(_ data: Data?, _ response: URLResponse?) {
        debugPrint { """

        Response:
        \(response as Any)

        Data:
        \(data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) } as Any)
        """
        }
    }

    private static func debugPrint(_ message: () -> String) {
        guard Env.current.debug else { return }

        Env.current.shell.write(message())
    }
}
