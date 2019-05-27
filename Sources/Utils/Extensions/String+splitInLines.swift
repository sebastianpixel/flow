import Foundation

public extension String {
    func splitBlockInLines(upToCharacters: Int) -> String {
        return components(separatedBy: .newlines)
            .map { $0.splitLineInLines(upToCharacters: upToCharacters) }
            .joined(separator: "\n")
    }

    func splitLineInLines(upToCharacters: Int) -> String {
        var lines = [String]()

        var characters = [Character]()
        characters.reserveCapacity(upToCharacters)

        var i = startIndex
        while i < endIndex {
            characters.append(self[i])

            if characters.count == upToCharacters {
                let nextIndex = index(after: i)
                guard nextIndex < endIndex else { continue }

                // Search backwards in saved characters for last whitespace,
                // add subrange from beginning of characters up to whitespace
                // to lines, make subrange from whitespace the new saved
                // characters and continue from there.
                if let nextScalar = self[nextIndex].unicodeScalars.first,
                    !CharacterSet.whitespaces.contains(nextScalar) {
                    var previousCharacterIndex = characters.endIndex - 1
                    while previousCharacterIndex > characters.startIndex,
                        let scalar = characters[previousCharacterIndex].unicodeScalars.first,
                        !CharacterSet.whitespaces.contains(scalar) {
                        previousCharacterIndex -= 1
                    }
                    lines.append(String(characters[..<previousCharacterIndex]))
                    characters = Array(characters[(previousCharacterIndex + 1)...])
                } else {
                    lines.append(String(characters))
                    characters.removeAll()
                    i = nextIndex // skip whitespace
                }
            }

            i = index(after: i)
        }
        lines.append(String(characters))

        return lines.joined(separator: "\n")
    }
}
