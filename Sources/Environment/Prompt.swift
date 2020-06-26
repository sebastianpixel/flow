import CommandLineKit

public struct Prompt {
    let color: TextColor
    private static let raw = "> "

    public init(color: TextColor = .green) {
        self.color = color
    }

    public var textProperties: TextProperties {
        .init(color, nil, .bold)
    }

    public var prefix: String {
        textProperties.apply(to: Prompt.raw)
    }

    public static var count: Int {
        raw.count
    }
}
