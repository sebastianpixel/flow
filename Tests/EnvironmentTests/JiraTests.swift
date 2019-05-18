import Environment
import XCTest

class JiraTest: XCTestCase {
    var commands = [String]()
    var prompts = [String]()

    var stringReturn = [String]()
    var booleanReturn = [Bool]()

    override func setUp() {
        super.setUp()

        Env.current = .mock

        let git = Env.current.git as! GitMock
        git.currentBranchCallback = {
            self.stringReturn.removeFirst()
        }
        git.domainCallback = git.currentBranchCallback

        let shell = Env.current.shell as! ShellMock
        shell.writeCallback = { text in
            self.commands.append(text)
        }
        shell.promptCallback = {
            self.prompts.append($0)
            return self.stringReturn.removeFirst()
        }
        shell.promptDecisionCallback = {
            self.prompts.append($0)
            return self.booleanReturn.removeFirst()
        }
    }

    func testCurrentProjectFromCurrentBranch() {
        stringReturn = ["feature-PROJECT-1234-summary-goes-here"]

        XCTAssertEqual(Env.current.jira.currentProject, "PROJECT")
    }

    func testCurrentIssueKeyFromCurrentBranch() {
        stringReturn = ["feature-PROJECT-1234-summary-goes-here"]

        XCTAssertEqual(Env.current.jira.currentIssueKey(), "PROJECT-1234")
    }

    func testCurrentIssueKeyWithoutCurrentBranchWithoutEnteringProject() {
        stringReturn = ["master"]
        booleanReturn = [false]

        XCTAssertNil(Env.current.jira.currentIssueKey())
        XCTAssertEqual(prompts, ["Want to enter a key?"])
        XCTAssertEqual(commands, ["Could not retrieve key of current issue. Make sure you checked out a branch that has the key of a JIRA ticket in its name."])
    }

    func testCurrentIssueKeyWithoutCurrentBranchWithEnteringProjectWithNumber() {
        stringReturn = ["master", "PROJECT-1234"]
        booleanReturn = [true]

        XCTAssertEqual(Env.current.jira.currentIssueKey(), "PROJECT-1234")
        XCTAssertEqual(prompts, ["Want to enter a key?", "Format: <PROJECT-1234>"])
        XCTAssertEqual(commands, ["Could not retrieve key of current issue. Make sure you checked out a branch that has the key of a JIRA ticket in its name."])
    }

    func testCurrentIssueKeyWithoutCurrentBranchWithEnteringProjectWithoutNumber() {
        stringReturn = ["master", "PROJECT"]
        booleanReturn = [true]

        XCTAssertNil(Env.current.jira.currentIssueKey())
        XCTAssertEqual(prompts, ["Want to enter a key?", "Format: <PROJECT-1234>"])
        XCTAssertEqual(commands, ["Could not retrieve key of current issue. Make sure you checked out a branch that has the key of a JIRA ticket in its name."])
    }

    func testCurrentIssueKeyWithoutCurrentBranchWithEnteringMalformedProject() {
        stringReturn = ["master", "asdf"]
        booleanReturn = [true]

        XCTAssertNil(Env.current.jira.currentIssueKey())
        XCTAssertEqual(prompts, ["Want to enter a key?", "Format: <PROJECT-1234>"])
        XCTAssertEqual(commands, ["Could not retrieve key of current issue. Make sure you checked out a branch that has the key of a JIRA ticket in its name."])
    }

    func testHost() {
        stringReturn = ["company.com"]

        XCTAssertEqual(Env.current.jira.host, "jira.company.com")
    }
}
