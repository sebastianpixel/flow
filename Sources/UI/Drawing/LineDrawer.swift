import CommandLineKit
import Environment

public class LineDrawer {
    public let linesToDrawCount: Int

    public init(linesToDrawCount: Int) {
        self.linesToDrawCount = linesToDrawCount
    }

    public func reset(lines: Int? = nil) {
        for _ in 0 ..< (lines ?? linesToDrawCount) {
            Env.current.shell.write(AnsiCodes.cursorUp(1) + AnsiCodes.clearLine + AnsiCodes.beginningOfLine, terminator: "")
        }
    }

    public func drawLines(_ lines: [String], cursorColumn: Int = 0) {
        for index in Array(0 ..< linesToDrawCount).reversed() {
            let line: String
            if index < lines.count {
                line = lines[index]
            } else {
                line = ""
            }
            draw(line, cursorColumn: cursorColumn)
        }
    }

    public func draw(_ line: String, cursorColumn: Int) {
        Env.current.shell.write(
            line
                + AnsiCodes.setCursorColumn(cursorColumn)
                + "\n"
                + AnsiCodes.beginningOfLine
                + AnsiCodes.clearLine,
            terminator: ""
        )
    }
}
