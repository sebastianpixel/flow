import CommandLineKit

final class Cursor {
    private(set) var column: Int
    private(set) var row: Int

    let defaultPosition: (column: Int, row: Int)

    init(column: Int, row: Int) {
        self.column = column
        self.row = row
        defaultPosition = (column, row)
    }

    var isInDefaultRow: Bool {
        row == defaultPosition.row
    }

    func resetRow() {
        row = defaultPosition.row
    }

    func resetColumn() {
        column = defaultPosition.column
    }

    func moveUp() {
        row += 1
    }

    func moveDown() {
        guard row > defaultPosition.row else { return }
        row -= 1
    }

    func moveLeft() {
        guard column > defaultPosition.column else { return }
        column -= 1
    }

    func moveRight() {
        column += 1
    }

    func moveToColumn(_ column: Int) {
        self.column = defaultPosition.column + column
    }
}
