import Environment
import Foundation
import Utils

public struct CreateCommit: Procedure {
    private let message: String?
    private let prependWithIssueKey: Bool

    private static let maxCharactersInBodyLines = 72

    public init(message: String, prependWithIssueKey: Bool) {
        self.message = message
        self.prependWithIssueKey = prependWithIssueKey
    }

    public func run() -> Bool {
        guard let stagedFiles = Env.current.git.stagedFiles,
            !stagedFiles.isEmpty else {
            let status = Env.current.git.status(verbose: false)
            Env.current.shell.write(status ?? "Nothing to commit.")
            return false
        }

        var body = ""
        var subject = self.message ?? ""
        let subjectIsEmpty = subject.isEmpty

        if prependWithIssueKey,
            let key = Env.current.jira.currentIssueKey() {
            subject = "[\(key)] \(subject)"
        }

        // Subject and Body are preserved in case the previous commit did not finish successfully.
        // In this case the template is pupulated with the previous values to avoid having to
        // retype the message.

        if let lastCommitSubject = Env.current.defaults.get(String.self, for: .lastCommitSubject),
            let lastCommitBody = Env.current.defaults.get(String.self, for: .lastCommitBody) {
            subject = lastCommitSubject
            body = lastCommitBody.isEmpty ? "" : "\(lastCommitBody)\n"
        }

        if subjectIsEmpty,
            let root = Env.current.git.rootDirectory,
            let commitFile = try? Env.current.file.init(path: "\(root)/.git/COMMIT_EDITMSG") { template(subject: subject, body: body) },
            Env.current.shell.runForegroundTask("\(Env.current.shell.editor) \(commitFile.path)") {
                let content = commitFile.parse(markEndLinePrefix: "# On branch")

                subject = content.first { !$0.isEmpty } ?? ""

                guard !subject.isEmpty else {
                    Env.current.shell.write("Aborting commit due to empty subject.")
                    return false
                }

                body = content.drop { $0.isEmpty || $0 == subject }
                    .map { $0.splitLineInLines(upToCharacters: CreateCommit.maxCharactersInBodyLines) }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
            }

        var message = subject
        if !body.isEmpty {
            message += "\n\n\(body)"
        }

        let commitWasSuccessful = Env.current.git.commit(message: message)

        if !commitWasSuccessful {
            Env.current.defaults.set(subject, for: .lastCommitSubject)
            Env.current.defaults.set(body, for: .lastCommitBody)
        } else {
            Env.current.defaults.removeObject(for: .lastCommitSubject)
            Env.current.defaults.removeObject(for: .lastCommitBody)
        }

        return commitWasSuccessful
    }

    private func template(subject: String, body: String) -> String {
        return """
        \(subject)
        \(body)
        \(Env.current.git.status(verbose: false)?.components(separatedBy: .newlines).map { "# \($0)" }.joined(separator: "\n") ?? "")

        \(Env.current.git.stagedDiff(linesOfContext: 2) ?? "")
        """
    }
}
