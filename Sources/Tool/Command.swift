import CommandLineKit

public final class Command {
    let name: String
    private(set) var handler: (() -> Void)?
    private let aliases: [String]
    private let description: String
    private let toolName: String

    init(toolName: String, name: String, aliases: [String], description: String = "") {
        self.name = name
        self.aliases = aliases
        self.description = description
        self.toolName = toolName
    }

    var registeredFlags = [(shortName: Character?, longName: String?, description: String, register: (Flags) -> Void)]()

    func usageDescription(ansi: Bool) -> String {
        let commandName = ([name] + aliases).joined(separator: ", ")
        let commandNameStyled = ansi ? TextColor.green.properties.apply(to: commandName) : commandName
        let flags = Flags(toolName: commandNameStyled, arguments: [])
        registeredFlags
            .sorted {
                let first = $0.longName ?? $0.shortName.map(String.init)!
                let second = $1.longName ?? $1.shortName.map(String.init)!
                return first < second
            }
            .forEach { flag in _ = flag.register(flags) }
        let optionsName = "Options:"
        let synopsisOptions = "<options>"
        let synopsisDesciption = description.isEmpty ? "" : "\n\(ansi ? description.styled(.italic) : description)"
        var usageDescription = flags.usageDescription(usageName: toolName,
                                                      synopsis: "\(synopsisOptions)\(synopsisDesciption)",
                                                      usageStyle: .none,
                                                      optionsName: optionsName,
                                                      flagStyle: ansi ? TextStyle.italic.properties : .none,
                                                      indent: "  ")

        if let optionsNameRange = usageDescription.range(of: "\(optionsName)\n"),
            optionsNameRange.upperBound.utf16Offset(in: usageDescription) == usageDescription.count,
            let synopsisRange = usageDescription.range(of: synopsisOptions) {
            usageDescription.removeSubrange(optionsNameRange)
            usageDescription.removeSubrange(synopsisRange)
        }

        return usageDescription
    }

    /// convenvience wrapper around assignment to local var `handler`
    public func handler(block: @escaping () -> Void) {
        handler = block
    }

    public func option(
        shortName: Character? = nil,
        longName: String? = nil,
        description: String
    ) -> Option {
        let option = Option(shortName: shortName, longName: longName, description: description)
        registeredFlags.append((shortName, longName, description, { $0.register(option) }))
        return option
    }

    public func argument<T: ConvertibleFromString>(
        _: T.Type,
        shortName: Character? = nil,
        longName: String? = nil,
        description: String
    ) -> SingletonArgument<T> {
        let flag = SingletonArgument<T>(shortName: shortName, longName: longName, paramIdent: nil, description: description, value: nil)
        registeredFlags.append((shortName, longName, description, { $0.register(flag) }))
        return flag
    }

    public func arguments<T: ConvertibleFromString>(
        _: T.Type,
        shortName: Character? = nil,
        longName: String? = nil,
        description: String
    ) -> RepeatedArgument<T> {
        let flag = RepeatedArgument<T>(shortName: shortName, longName: longName, description: description)
        registeredFlags.append((shortName, longName, description, { $0.register(flag) }))
        return flag
    }
}
