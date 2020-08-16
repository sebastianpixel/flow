import Environment
import Foundation
import Utils

extension File {
    /**
     Parses the content of a file until an optional end marker.

     - Parameter markEndLinePrefix: Optional marker for where parsing should stop

     - Returns: The array of parsed lines.
     */
    func parse(markEndLinePrefix: String? = nil) -> [String] {
        parse(markSwitchToSecondBlockLinePrefix: nil, markEndLinePrefix: markEndLinePrefix).firstBlock
    }

    /**
     Parses the content of a file and splits its line based on an optional line prefix marker until an optional end marker.

     - Parameter markSwitchToSecondBlockLinePrefix: Optional marker that splits the lines in the returned tuple.
     - Parameter markEndLinePrefix: Optional marker for where parsing should stop

     - Returns: A tuple with the all lines until the `switchToSecondBlock`
                marker and all lines from there until the optional end
                marker (or the end of the file).
     */
    func parse(markSwitchToSecondBlockLinePrefix: String?, markEndLinePrefix: String? = nil) -> (firstBlock: [String], secondBlock: [String]) {
        let content: String
        do {
            content = try read()
        } catch {
            Env.current.shell.write("\(error)")
            exit(EXIT_FAILURE)
        }
        var firstBlockLines = [String]()
        var secondBlockLines = [String]()

        var switchToSecond = false

        for line in content.components(separatedBy: .newlines).map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if let endMarker = markEndLinePrefix,
                line.hasPrefix(endMarker)
            {
                break
            } else if let markSwitchToSecondBlockLinePrefix = markSwitchToSecondBlockLinePrefix,
                line.hasPrefix(markSwitchToSecondBlockLinePrefix)
            {
                switchToSecond = true
            } else if line.hasPrefix("#") {
                continue
            } else if switchToSecond {
                secondBlockLines.append(line)
            } else {
                firstBlockLines.append(line)
            }
        }

        return (firstBlockLines, secondBlockLines)
    }
}
