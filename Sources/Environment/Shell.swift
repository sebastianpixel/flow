import Foundation
import Utils

public protocol Shell {
    var editor: String { get }
    var numColumns: Int { get }

    func prompt(_ str: String) -> String?
    func prompt(_ str: String, newline: Bool, silent: Bool) -> String?
    func promptDecision(_ str: String) -> Bool
    func write(_ text: String)
    func write(_ text: String, terminator: String)
    func run(_ command: String) -> Bool
    func run(_ command: String) -> String?
    func runForegroundTask(_ command: String) -> Bool
}

struct ShellImpl: Shell {
    var editor: String {
        return run("git config --global core.editor") ?? "vim"
    }

    func prompt(_ str: String) -> String? {
        return prompt(str, newline: true, silent: false)
    }

    func prompt(_ str: String, newline: Bool, silent: Bool) -> String? {
        let template = "\(Prompt().prefix)\(str): "
        if silent {
            if newline {
                write("")
            }
            return String(cString: getpass(template))
        } else {
            write(template, terminator: newline ? "\n" : "")
            return readLine()
        }
    }

    func promptDecision(_ str: String) -> Bool {
        let answer = prompt(str + " [y/N]", newline: false, silent: false)
        return answer.map { ["y", "Y", ""].contains($0.trimmingCharacters(in: .whitespaces)) } == true
    }

    func write(_ text: String) {
        write(text, terminator: "\n")
    }

    func write(_ text: String, terminator: String) {
        print(text, separator: " ", terminator: terminator)
    }

    func run(_ command: String) -> Bool {
        let (output, success) = self.command(command)
        if let output = output?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
            write(output)
        }
        return success
    }

    func run(_ command: String) -> String? {
        let (output, success) = self.command(command)
        if success {
            let trimmed = output?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == true ? nil : trimmed
        } else {
            output.map { write($0) }
            return nil
        }
    }

    private func command(_ command: String) -> (output: String?, success: Bool) {
        let launchPath = "/bin/bash"
        let arguments = ["-c", command]

        printDebugDescription(command: command)

        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        printDebugDescription(output: output)

        task.waitUntilExit()
        return (output, task.terminationStatus == EXIT_SUCCESS)
    }

    func runForegroundTask(_ command: String) -> Bool {
        let launchPath = "/bin/bash"
        let arguments = ["-c", command]

        printDebugDescription(command: command)

        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.launch()

        tcsetpgrp(STDIN_FILENO, task.processIdentifier)

        task.waitUntilExit()

        // Apparently when trying to get back to foreground
        // this process receives a SIGTTOU signal.

        // SIGTTOU: stopped signal

        // SIG_IGN & SIG_DFL define signal handling strategies
        // SIG_IGN: signal is ignored
        // SIG_DFL: default signal handling
        // https://en.cppreference.com/w/c/program/SIG_strategies

        signal(SIGTTOU, SIG_IGN)
        tcsetpgrp(STDIN_FILENO, getpid())
        signal(SIGTTOU, SIG_DFL)

        return task.terminationStatus == EXIT_SUCCESS
    }

    private func printDebugDescription(command: String) {
        if Env.current.debug {
            Env.current.shell.write("> \(command)")
        }
    }

    private func printDebugDescription(output: String?) {
        if Env.current.debug {
            output
                .flatMap { $0.isEmpty ? nil : $0 }
                .map { Env.current.shell.write("\($0)".styled(.dim)) }
        }
    }

    var numColumns: Int {
        var winSize = winsize()
        if ioctl(1, UInt(TIOCGWINSZ), &winSize) == -1 || winSize.ws_col == 0 {
            return 80
        } else {
            return Int(winSize.ws_col)
        }
    }
}
