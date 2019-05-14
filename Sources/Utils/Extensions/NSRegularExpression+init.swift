import class Foundation.NSRegularExpression

public extension NSRegularExpression {
    convenience init(_ pattern: StaticString) {
        do {
            try self.init(pattern: String(cString: pattern.utf8Start))
        } catch {
            preconditionFailure("Bad regex: \(pattern)")
        }
    }
}
