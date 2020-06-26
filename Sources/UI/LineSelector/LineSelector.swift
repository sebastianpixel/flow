import CommandLineKit
import Environment
import Foundation
import Utils

public final class LineSelector<DataSource: LineSelectorDataSource> {
    public typealias SingleSelection = (input: String, output: DataSource.Model?)
    public typealias MultiSelection = (input: String, output: [DataSource.Model])

    private class Line: Equatable {
        static func == (lhs: LineSelector<DataSource>.Line, rhs: LineSelector<DataSource>.Line) -> Bool {
            lhs.text == rhs.text
        }

        var text: String
        var isSelected: Bool
        let item: DataSource.Item

        init(text: String, isSelected: Bool = false, item: DataSource.Item, numColumns: Int, promptCharCount: Int) {
            self.text = text
            self.isSelected = isSelected

            if item.line.count > numColumns - promptCharCount {
                var item = item
                let line = item.line
                item.line = String(line[line.startIndex ..< line.index(line.startIndex, offsetBy: numColumns - promptCharCount - 1)]) + "…"
                self.item = item
            } else {
                self.item = item
            }
        }
    }

    private let linesToDrawCount = 20

    // starts at minus one as 0 is the first of the drawn issues
    private let cursor = Cursor(column: Prompt.count + 1, row: -1)
    private let defaultPrompt = Prompt()
    private let hightlightTextProperties = TextProperties(.green, nil)
    private let multiselectPrompt = Prompt(color: .aqua)
    private let multiselectHighlightTextProperties = TextProperties(.aqua, nil)
    private let lineReader: LineReader
    private let lineDrawer: LineDrawer

    private let allLines: [Line]

    // Cache to avoid continuous filtering during scrolling
    private var filteredLines = [Line]()
    // Cache to check if new search term contains the old one to limit
    // filtering to already filtered lines.
    private var previousBuffer = ""

    // Range of issues to draw (for scrolling)
    private var drawnRange = 0 ..< 0

    // Allows selecting lines by hitting the tab key.
    private var isMultiselectEnabled = false

    public init?(dataSource: DataSource) {
        let numColumns = Env.current.shell.numColumns
        allLines = dataSource.items.map { Line(text: $0.line, item: $0, numColumns: numColumns, promptCharCount: Prompt.count) }

        lineDrawer = LineDrawer(linesToDrawCount: min(allLines.count, linesToDrawCount))

        guard let lineReader = LineReader() else { return nil }
        self.lineReader = lineReader
        setupLineReader()

        drawLines(from: allLines)
    }

    /// Allows selecting multiple items from the given array and returns the
    /// input String and an array of selected model objects.
    public func multiSelection() -> MultiSelection? {
        isMultiselectEnabled = true
        guard let input = waitForInput() else { return nil }

        var selectedModels = filteredLines.compactMap { $0.isSelected ? $0.item.model : nil }
        // If selectedModels is empty, i.e. no line was selected, multiSelection
        // behaves like singleSelection. If lines are already selected the line
        // at the cursor position should not be added when enter is pressed.
        if selectedModels.isEmpty,
            let selectedModel = selectedModel,
            !selectedModels.contains(where: { $0 == selectedModel }) {
            selectedModels.append(selectedModel)
        }

        return (input, selectedModels)
    }

    /// Allows selecting a single item from the given array and returns the input
    /// String and the selected model object.
    public func singleSelection() -> SingleSelection? {
        guard let input = waitForInput() else { return nil }

        return (input, selectedModel)
    }

    /// DataSource Model at cursor position
    private var selectedModel: DataSource.Model? {
        let selectedItem: DataSource.Item?
        if filteredLines[drawnRange].isEmpty {
            selectedItem = nil
        } else {
            let index = cursor.isInDefaultRow ? 0 : cursor.row
            selectedItem = filteredLine(at: index)?.item
        }
        return selectedItem?.model
    }

    /// Sets handlers for line refresh and input callbacks
    private func setupLineReader() {
        weak var `self` = self
        lineReader.setRefreshCallback { currentBuffer in
            guard let self = self else { return }
            self.lineDrawer.reset()
            // only refresh if cursor is in bottom row / text is entered
            guard self.cursor.isInDefaultRow else { return }

            let linesToFilter = currentBuffer.contains(self.previousBuffer) ? self.filteredLines : self.allLines
            self.drawLines(from: linesToFilter, containing: currentBuffer)
            self.previousBuffer = currentBuffer
        }
        lineReader.setInputCallback { self?.handle(input: $1, currentBuffer: $0) ?? true }
    }

    /// Blocks execution until the user hits enter or ESC, CtrlC.
    private func waitForInput() -> String? {
        let input = try? lineReader.readLine(prompt: "> ",
                                             maxCount: 200,
                                             printNewlineAfterSelection: false,
                                             strippingNewline: true,
                                             promptProperties: defaultPrompt.textProperties,
                                             readProperties: .none,
                                             parenProperties: .none)
        // only refresh if cursor is NOT in bottom row (see `setupLineReader`)
        if cursor.isInDefaultRow {
            lineDrawer.reset()
        }
        if input == "q", input == "exit" {
            exit(EXIT_SUCCESS)
        }
        return input
    }

    /// Reacts on input events to the terminal and sets the position of the
    /// cursor for selecting a line by moving up and down.
    private func handle(input: LineReader.Input, currentBuffer: String) -> Bool {
        switch input {
        case .ShiftTab where isMultiselectEnabled && !cursor.isInDefaultRow,
             .controlCharacter(.Tab) where isMultiselectEnabled && !cursor.isInDefaultRow && filteredLine(at: cursor.row) == filteredLines.last:
            selectLineInCursorRowWithoutRedrawing()
            moveDownIfPossible()
            return false
        case .controlCharacter(.Tab) where isMultiselectEnabled && cursor.isInDefaultRow:
            moveUpIfPossible()
            return false
        case .controlCharacter(.Tab) where isMultiselectEnabled && !cursor.isInDefaultRow:
            selectLineInCursorRowWithoutRedrawing()
            moveUpIfPossible()
            return false
        case .move(.up):
            moveUpIfPossible()
            return false
        case .move(.down):
            moveDownIfPossible()
            return false
        case .move(.left) where cursor.column > 3, .controlCharacter(.Backspace):
            cursor.resetRow()
            cursor.moveLeft()
            return true
        case .move(.right) where cursor.column < currentBuffer.count + cursor.defaultPosition.column:
            cursor.resetRow()
            cursor.moveRight()
            return true
        case .move(.home):
            cursor.resetRow()
            cursor.resetColumn()
            return true
        case .move(.end):
            cursor.resetRow()
            cursor.moveToColumn(currentBuffer.count)
            return true
        case .character:
            cursor.resetRow()
            cursor.moveRight()
            return true
        case .controlCharacter(.Enter):
            return true
        case .controlCharacter(.Esc), .controlCharacter(.CtrlC):
            lineDrawer.reset()
            exit(EXIT_SUCCESS)
        default:
            return true
        }
    }

    /// Move cursor up and scroll drawn lines if needed
    private func moveUpIfPossible() {
        if cursor.row < min(lineDrawer.linesToDrawCount, filteredLines[drawnRange].count) - 1 {
            cursor.moveUp()
        } else if drawnRange.upperBound < filteredLines.count {
            drawnRange = drawnRange.lowerBound + 1 ..< drawnRange.upperBound + 1
        } else {
            return
        }
        writeSelection()
        redrawWithoutFiltering()
    }

    /// Move cursor down and scroll drawn lines if needed
    private func moveDownIfPossible() {
        if cursor.row >= 0 {
            if cursor.row == 0, drawnRange.lowerBound > 0 {
                drawnRange = drawnRange.lowerBound - 1 ..< drawnRange.upperBound - 1
            } else {
                cursor.moveDown()
            }
            if cursor.row >= 0 {
                writeSelection()
            }
            redrawWithoutFiltering()
        }
    }

    /// Toggle selection state of line without redrawing
    private func selectLineInCursorRowWithoutRedrawing() {
        allLines
            .first { $0.text == filteredLine(at: cursor.row)?.text }?
            .isSelected
            .toggle()
    }

    /// Prints the currently selected row to the buffer (replaces the normal buffer).
    private func writeSelection() {
        guard let selected = filteredLine(at: cursor.row)?.text else { return }
        Env.current.shell.write(
            defaultPrompt.prefix
                + selected
                .stripping(.ansiColorCodePattern)
                .strippingPrefixes(preserveAsterisk: false),
            terminator: ""
        )
    }

    /// Filteres lines for those containing the given substring, updates `filteredLines`
    /// and draws the filtered lines to the screen.
    private func drawLines(from lines: [Line], containing substring: String = "") {
        filteredLines = filter(lines, containing: substring)
        drawnRange = 0 ..< min(filteredLines.count, lineDrawer.linesToDrawCount)
        let linesToDraw = filteredLines[drawnRange].map { "  \($0.text)" }
        lineDrawer.drawLines(linesToDraw)
    }

    /// Returns an array of lines in the given array that contains the provided string.
    private func filter(_ lines: [Line], containing substring: String) -> [Line] {
        lines.compactMap { line in
            let text = line.item.line

            if line.isSelected {
                line.text = hightlightTextProperties.apply(to: text)
            } else if substring.isEmpty {
                line.text = text
            } else if let lineTextRange = lineTextRange(in: text),
                let highlightedRange = text.range(of: substring, options: [.regularExpression, .caseInsensitive], range: lineTextRange) {
                let prefix = String(text[text.startIndex ..< highlightedRange.lowerBound])
                let highlighted = hightlightTextProperties.apply(to: String(text[highlightedRange]))
                let suffix = String(text[highlightedRange.upperBound ..< text.endIndex])
                line.text = prefix + highlighted + suffix
            } else {
                return nil
            }
            return line
        }
    }

    /// The range of text in the current line excluding prefixes (whitespace, asterisk).
    private func lineTextRange(in string: String) -> Range<String.Index>? {
        var nonPrefixes = CharacterSet(charactersIn: "* ")
        nonPrefixes.invert()
        return (string.rangeOfCharacter(from: nonPrefixes)?.lowerBound ?? string.startIndex) ..< string.endIndex
    }

    /// Iterates over the currently drawn lines and prefixes them either with two spaces
    /// or the prompt symbol if matches the row of the cursor and highlights selected ones.
    private func redrawWithoutFiltering() {
        let newLines = filteredLines[drawnRange].enumerated().reduce(into: [String]()) { lines, current in
            let (index, line) = current
            let newLine: String

            if index == cursor.row {
                if isMultiselectEnabled, !line.isSelected {
                    newLine = "\(multiselectPrompt.prefix)\(multiselectHighlightTextProperties.apply(to: line.item.line))"
                } else {
                    newLine = "\(defaultPrompt.prefix)\(hightlightTextProperties.apply(to: line.item.line))"
                }
            } else if line.isSelected {
                newLine = "  \(hightlightTextProperties.apply(to: line.item.line))"
            } else {
                newLine = "  \(line.item.line)"
            }

            lines.append(newLine)
        }

        lineDrawer.reset()
        lineDrawer.drawLines(newLines, cursorColumn: cursor.column)
    }

    /// Performs a lookup for a line at a provided index in `filteredLines` without creating a new Array.
    private func filteredLine(at index: Int) -> Line? {
        filteredLines
            .index(drawnRange.startIndex, offsetBy: index, limitedBy: drawnRange.endIndex)
            .map { filteredLines[$0] }
    }
}
