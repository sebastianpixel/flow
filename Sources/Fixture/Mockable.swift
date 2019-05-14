import Foundation
import Model
import Utils

public protocol Mockable {
    static var fixture: Fixture { get }
}

public extension Mockable where Self: Decodable {
    static var mock: Self {
        return try! fixture.encoded.decoded(Self.self)
    }
}

extension Commit.Response: Mockable {
    public static let fixture = Fixture.commits
}

extension Empty: Mockable {
    public static let fixture = Fixture.empty
}

extension Issue: Mockable {
    public static let fixture = Fixture.issue
}

extension Issue.Response: Mockable {
    public static let fixture = Fixture.issues
}

extension PullRequest.Response: Mockable {
    public static let fixture = Fixture.pullRequests
}

// Right now it's not possible to add multiple conditional conformances
// https://forums.swift.org/t/conditional-conformance-problems/19633
// The suggested alternative is not working as the Array is not handled
// as such but just as Mockable.
extension Array: Mockable {
    public static var fixture: Fixture {
        if Element.self == Reviewer.self {
            return Fixture.reviewers
        } else if Element.self == Project.self {
            return Fixture.projects
        }
        fatalError("No fixture associated with \(type(of: Element.self)).")
    }
}

extension Sprint.Response: Mockable {
    public static let fixture = Fixture.sprints
}

extension Transition.Response: Mockable {
    public static let fixture = Fixture.transitions
}
