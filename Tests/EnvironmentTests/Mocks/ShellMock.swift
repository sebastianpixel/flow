import Environment

class ShellMock: Shell {
    var numColumnsCallback = { 80 }
    var numColumns: Int {
        numColumnsCallback()
    }

    var editorCallback = { "vim" }
    var editor: String {
        editorCallback()
    }

    var promptCallback: (String) -> String? = { _ in nil }
    func prompt(_ str: String) -> String? {
        promptCallback(str)
    }

    var promptWithNewlineAndSilentCallback: (String, Bool, Bool) -> String? = { _, _, _ in nil }
    func prompt(_ str: String, newline: Bool, silent: Bool) -> String? {
        promptWithNewlineAndSilentCallback(str, newline, silent)
    }

    var promptDecisionCallback: (String) -> Bool = { _ in false }
    func promptDecision(_ str: String) -> Bool {
        promptDecisionCallback(str)
    }

    var writeCallback: (String) -> Void = { _ in }
    func write(_ text: String) {
        writeCallback(text)
    }

    var writeWithTerminatorCallback: (String, String) -> Void = { _, _ in }
    func write(_ text: String, terminator: String) {
        writeWithTerminatorCallback(text, terminator)
    }

    var runReturningStringCallback: (String) -> String? = { _ in nil }
    func run(_ command: String) -> Bool {
        runReturningBoolCallback(command)
    }

    var runReturningBoolCallback: (String) -> Bool = { _ in false }
    func run(_ command: String) -> String? {
        runReturningStringCallback(command)
    }

    var runForegroundTaskCallback: (String) -> Bool = { _ in false }
    func runForegroundTask(_ command: String) -> Bool {
        runForegroundTaskCallback(command)
    }
}
