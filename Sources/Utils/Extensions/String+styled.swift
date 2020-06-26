import CommandLineKit

public extension String {
    func styled(_ textStyle: TextStyle) -> String {
        textStyle.properties.apply(to: self)
    }
}
