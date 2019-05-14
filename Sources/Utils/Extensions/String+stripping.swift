import Foundation

public extension String {
    static let ansiCodePattern = "\\x1b\\[[0-9;]*[a-zA-Z]"
    static let ansiColorCodePattern = "\\x1b\\[[0-9;]*m"
    static let promptPattern = ">?\\s*"

    func stripping(_ pattern: String) -> String {
        let string = NSMutableString(string: self)
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: string.length)
        regex?.replaceMatches(in: string, options: [], range: range, withTemplate: "")
        return String(string)
    }

    func strippingPrefixes(preserveAsterisk: Bool) -> String {
        var string = self
        let pattern = "(\(String.ansiCodePattern))*\(String.promptPattern)\\s*" + (preserveAsterisk ? "" : "\\*?\\s*")
        if let range = string.range(of: pattern, options: .regularExpression) {
            string.removeSubrange(range)
        }
        return string
    }
}
