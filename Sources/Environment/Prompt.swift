import CommandLineKit

public struct Prompt {
    let color: TextColor
    private static let raw = "> "

    public init(color: TextColor = .green) {
        self.color = color
    }

    public var textProperties: TextProperties {
        return .init(color, nil, .bold)
    }

    public var prefix: String {
        return textProperties.apply(to: Prompt.raw)
    }

    public static var count: Int {
        return raw.count
    }
}
