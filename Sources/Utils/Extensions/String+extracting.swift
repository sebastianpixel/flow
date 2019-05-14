public extension String {
    static let uppercasesPattern = "[[:upper:]]+"
    static let numbersPattern = "[[:digit:]]+"
    static let jiraIssueKeyPattern = "[[:upper:]]+[[:punct:]][[:digit:]]+"

    func extracting(_ pattern: String) -> String? {
        return range(of: pattern, options: .regularExpression)
            .map { String(self[$0]) }
    }
}
