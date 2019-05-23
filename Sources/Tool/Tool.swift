import CommandLineKit
import Environment

public final class Tool {
    let toolName: String
    private let globalFlags = "<global_flags>"

    private var commands = [String: Command]()

    @discardableResult
    public init(name: String, arguments: [String], decorator: (Tool) -> Void) {
        toolName = name
        decorator(self)

        var arguments = groupArguments(arguments)

        let (failures, commandWasRun) = parse(arguments)

        if !failures.isEmpty {
            let failures = failures
                .map { "\($0.failure)\n\nUsage:\n\($0.command.usageDescription(ansi: true))" }
                .joined(separator: "\n")
            Env.current.shell.write(failures)
        }

        guard !commandWasRun else { return }

        arguments = arguments.filter { $0.components(separatedBy: .whitespaces).count == 1 }.map { "\"\($0)\"" }

        guard !arguments.isEmpty else { return }

        Env.current.shell.write("No command found for: \(arguments.joined(separator: ", "))")
        Env.current.shell.write("Did you mean one of those?")

        commands.keys
            .filter { cmd in
                cmd != globalFlags && arguments.contains(where: { $0.dropFirst().first.map(String.init).map(cmd.hasPrefix) ?? false })
            }
            .sorted()
            .forEach { cmd in
                Env.current.shell.write("    \(cmd)")
            }
    }

    public func usageDescription(ansi: Bool) -> String {
        let name = ansi ? TextColor.green.properties.apply(to: toolName) : toolName
        return "\(name) <command> <options>\n\n"
            + commands.values
            .sorted { $0.name < $1.name }
            .reduce(into: "") { usageDescription, command in
                if !usageDescription.contains(command.usageDescription(ansi: ansi)) {
                    usageDescription += command.usageDescription(ansi: ansi) + "\n"
                }
            }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func registerCommand(_ name: String, _ aliases: String..., description: String = "", decorator: @escaping (Command) -> Void) {
        let cmd = Command(toolName: toolName, name: name, aliases: aliases, description: description)
        decorator(cmd)
        for name in [name] + aliases {
            guard commands[name] == nil else { fatalError("Command \(name) was already registered!") }
            commands[name] = cmd
        }
        // Add default help flag if there are options and there is no custom help flag.
        if !cmd.registeredFlags.isEmpty,
            !cmd.registeredFlags.contains(where: { $0.shortName == "h" || $0.longName == "help" }) {
            let option = Option(shortName: "h",
                                longName: "help",
                                description: "Print the usage description of '\(cmd.name)'.") {
                Env.current.shell.write(cmd.usageDescription(ansi: true))
                cmd.handler {} // set empty handler to block default behaviour
            }
            cmd.registeredFlags.append((option.shortName, option.longName, option.helpDescription, { $0.register(option) }))
        }
    }

    public func registerGlobalFlags(description: String, decorator: @escaping (Command) -> Void) {
        registerCommand(globalFlags, description: description, decorator: decorator)
    }

    private func groupArguments(_ arguments: [String]) -> [String] {
        var activeQuotes = Character?.none

        return arguments.enumerated().reduce(into: [String]()) { arguments, current in
            let (index, argument) = current
            if activeQuotes == nil,
                let first = argument.first,
                first == "\"" || first == "\'" {
                activeQuotes = first
                arguments.append(String(argument.dropFirst()))
            } else if let quotes = activeQuotes {
                arguments[index] += " \(argument)"
                if argument.hasSuffix("\(quotes)") {
                    activeQuotes = nil
                }
            } else {
                arguments.append("\(argument)")
            }
        }
    }

    private func parse(_ arguments: [String]) -> (failures: [(failure: String, command: Command)], commandWasRun: Bool) {
        var savedArguments = [String]()
        var savedCommand = commands[globalFlags]

        var parsingFailures = [(failure: String, command: Command)]()
        var commandWasRun = false

        let buildAndRunCommand = {
            if let oldCommand = savedCommand {
                let flags = Flags(toolName: "\(self.toolName) \(oldCommand.name)", arguments: savedArguments)

                // set flags
                for flag in oldCommand.registeredFlags {
                    flag.register(flags)
                }
                // parse arguments passed in init
                if let parsingFailure = flags.parsingFailure() {
                    parsingFailures.append((parsingFailure, oldCommand))
                }

                oldCommand.handler?()

                savedArguments.removeAll()

                if oldCommand.name == self.globalFlags, !flags.descriptors.contains(where: { $0.wasSet }) {
                    return
                }
                commandWasRun = true
            }
        }

        for argument in arguments {
            if let newCommand = commands[argument] {
                buildAndRunCommand()
                savedCommand = newCommand
            } else if savedCommand != nil {
                savedArguments.append(argument)
            }
        }
        buildAndRunCommand()

        return (parsingFailures, commandWasRun)
    }
}
