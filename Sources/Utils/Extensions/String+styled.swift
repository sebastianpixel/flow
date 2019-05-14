import CommandLineKit

public extension String {
    func styled(_ textStyle: TextStyle) -> String {
        return textStyle.properties.apply(to: self)
    }
}
