import Environment

class ShellMock: Shell {
    var editorCallback = { "vim" }
    var editor: String {
        return editorCallback()
    }

    var promptCallback: (String) -> String? = { _ in nil }
    func prompt(_ str: String) -> String? {
        return promptCallback(str)
    }

    var promptSilentCallback: (String, Bool) -> String? = { _, _ in nil }
    func prompt(_ str: String, silent: Bool) -> String? {
        return promptSilentCallback(str, silent)
    }

    var promptDecisionCallback: (String) -> Bool = { _ in false }
    func promptDecision(_ str: String) -> Bool {
        return promptDecisionCallback(str)
    }

    var writeWithTerminatorCallback: (String, String) -> Void = { _, _ in }
    func write(_ text: String, terminator: String) {
        writeWithTerminatorCallback(text, terminator)
    }

    var runReturningStringCallback: (String) -> String? = { _ in nil }
    func run(_ command: String) -> Bool {
        return runReturningBoolCallback(command)
    }

    var runReturningBoolCallback: (String) -> Bool = { _ in false }
    func run(_ command: String) -> String? {
        return runReturningStringCallback(command)
    }

    var runForegroundTaskCallback: (String) -> Bool = { _ in false }
    func runForegroundTask(_ command: String) -> Bool {
        return runForegroundTaskCallback(command)
    }
}
