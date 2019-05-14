import Environment
import Foundation
import Model

public struct IssueLineSelectorDataSource: LineSelectorDataSource {
    public let items: [(line: String, model: Issue)]

    public init(issues: [Issue]) {
        var containerDict = [String: (parent: Issue?, children: [Issue])]()

        for issue in issues {
            if let parent = issue.fields.parent {
                if containerDict[parent.key] != nil {
                    containerDict[parent.key]?.children.append(issue)
                } else {
                    containerDict[parent.key] = (nil, [issue])
                }
            } else {
                if let group = containerDict[issue.key] {
                    containerDict[issue.key] = (issue, group.children)
                } else {
                    containerDict[issue.key] = (issue, [])
                }
            }
        }

        let pairs: [(parent: Issue, children: [Issue])] = containerDict
            .compactMap {
                guard let parent = $0.value.parent else { return nil }
                return (parent, $0.value.children)
            }
            .sorted { IssueLineSelectorDataSource.lastUpdated($0) > IssueLineSelectorDataSource.lastUpdated($1) }

        items = pairs.flatMap { parent, children -> [Item] in
            let parent = (parent.branchName, parent)
            let children = children
                .sorted { $0.id > $1.id }
                .map { ("*  " + $0.branchName, $0) }
            return children + [parent]
        }
    }

    private static func lastUpdated(_ pair: (parent: Issue, children: [Issue])) -> Date {
        return pair.children.reduce(pair.parent.fields.updated ?? .distantPast) { result, current -> Date in
            max(result, current.fields.updated ?? .distantPast)
        }
    }
}
