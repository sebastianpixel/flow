import Environment
import Utils

public struct GenerateReadme: Procedure {
    private let usageDescription: String

    public init(usageDescription: String) {
        self.usageDescription = usageDescription
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
    }

    public func run() -> Bool {
        guard let rootDirectory = Env.current.git.rootDirectory else {
            return false
        }

        do {
            try Env.current.file.init(path: .init(stringLiteral: "\(rootDirectory)/README.md")) {
                #"""
                # flow

                flow is a command line tool that links a few things I continuously happen to do in my every day life as a mobile developer.

                It's based on the Atlassian stack (stash & JIRA server) and makes a few assumptions about

                * workflows,
                * existing JIRA issue types,
                * (branch) naming conventions,
                * the URLs of stash & JIRA (as subdomains of 'company.com', which is retrieved from 'git remote -v')
                * the login is global and not based on the repo for example
                * and probably a few things more…

                flow is also a playground for me to try out things in Swift, the Swift Package Manager and in general to learn about new things I come across while implementing new features.

                ## Running it
                flow requires macOS 10.2 with Swift 5 installed. The following will clone the repo, build the executable and create a symbolic link from your binaries folder to the executable:
                ```bash
                git clone https://github.com/sebastianpixel/flow.git \
                && cd flow \
                && swift build -c release \
                && ln -s `pwd`/.build/release/flow /usr/local/bin/flow
                ```

                ## Commands
                ### Start working on an issue
                `flow init <options>` will

                * create a branch based on your selection from the last updated issues and their sub-tasks in the format `<issuetype>-<PROJECT>-<number>-<train-cased-issue-title>`,
                * push the branch upstream,
                * assign the JIRA issue to you and
                * update its status to `In Progress`.

                ### Track To-Dos
                Add, edit, complete, delete to-do items with `flow todo` relative to the current repo, branch or without such constraint (based on iCloud reminders).

                ### Create a PR
                Use `flow pr <options>` to

                * write the PR description in the editor specified in your global git config,
                * select a destination branch (or just use the branch of the parent issue),
                * assign the PR to reviewers (or pick the default reviewers of the repo) and
                * update the JIRA issue to `Ready To Review`.
                * `flow pr -m` finally merges the pull request and
                * shows a list of status for the issue to select from.

                ### The full list
                Taken from the usage description (`flow {,help,-h,--help}`):

                ```
                \#(usageDescription)
                ```
                """#
            }
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }

        return true
    }
}
