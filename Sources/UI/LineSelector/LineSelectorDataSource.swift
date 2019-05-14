public protocol LineSelectorDataSource {
    associatedtype Model: Equatable
    typealias Item = (line: String, model: Model)

    var items: [Item] { get }
}
