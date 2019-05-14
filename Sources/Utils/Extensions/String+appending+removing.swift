public extension String {
    func appendingIfNeeded(suffix: String) -> String {
        if hasSuffix(suffix) {
            return self
        } else {
            return appending(suffix)
        }
    }

    func removingIfNeeded(suffix: String) -> String {
        if hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        } else {
            return self
        }
    }
}
