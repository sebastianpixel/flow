import Environment
import Foundation
import Model

public struct GetProjects: Request {
    public init() {}

    public typealias Response = Project.Response

    public let method = HTTPMethod.get
    public let host = Env.current.jira.host
    public let path = "/rest/api/2/project"
    public let httpBody = Data?.none
    public let queryItems = [URLQueryItem]()
}
