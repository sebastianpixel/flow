import Foundation

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
    return formatter
}()

public extension Encodable {
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(formatter)
        return try encoder.encode(self)
    }
}

public extension Data {
    func decoded<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(type, from: self)
    }
}
