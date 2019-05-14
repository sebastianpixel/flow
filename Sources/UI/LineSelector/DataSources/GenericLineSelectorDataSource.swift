public struct GenericLineSelectorDataSource<Model: Equatable>: LineSelectorDataSource {
    public var items: [(line: String, model: Model)]

    public init(items: [Model], line: (Model) -> String) {
        self.items = items.map { (line($0), $0) }
    }

    public init(items: [Model], line: KeyPath<Model, String>) {
        self.items = items.map { ($0[keyPath: line], $0) }
    }
}

public extension GenericLineSelectorDataSource where Model == String {
    init(items: [String]) {
        self.init(items: items, line: \.self)
    }
}
