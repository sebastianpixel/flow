import CommandLineKit
import Environment
import Procedure

public final class Tool {
    let toolName: String
    private let globalFlags = "<global_flags>"

    private var commands = [String: Command]()

    @discardableResult
    public init(name: String, arguments: [String], decorator: (Tool) -> Void) {
        toolName = name
        decorator(self)

        if let parsingFailures = parsingFailures(arguments) {
            let failures = parsingFailures
                .map { "\($0.failure)\n\nUsage:\n\($0.command.usageDescription(ansi: true))" }
                .joined(separator: "\n")
            Env.current.shell.write(failures)
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

    private func parsingFailures(_ arguments: [String]) -> [(failure: String, command: Command)]? {
        var savedArguments = [String]()
        var savedCommand = commands[globalFlags]

        var parsingFailures = [(failure: String, command: Command)]()

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
            }
        }

        var activeQuotes = Character?.none

        for argument in arguments {
            if activeQuotes == nil,
                let first = argument.first,
                first == "\"" || first == "\'" {
                activeQuotes = first
            }

            if let quotes = activeQuotes,
                argument.hasSuffix("\(quotes)") {
                activeQuotes = nil
            }

            if activeQuotes == nil,
                let newCommand = commands[argument] {
                buildAndRunCommand()
                savedCommand = newCommand
            } else if savedCommand != nil {
                savedArguments.append(argument)
            }
        }
        buildAndRunCommand()

        return parsingFailures.isEmpty ? nil : parsingFailures
    }
}
