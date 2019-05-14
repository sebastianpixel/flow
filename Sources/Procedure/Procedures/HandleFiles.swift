import Environment
import Foundation
import UI

public struct HandleFiles: Procedure {
    public enum Mode: String {
        case add, remove
    }

    private let mode: Mode
    private let untracked, unstaged: Bool

    public init(_ mode: Mode, untracked: Bool, unstaged: Bool) {
        self.mode = mode
        self.untracked = untracked
        self.unstaged = unstaged
    }

    public func run() -> Bool {
        var fileTypes = [GitFileType]()
        if unstaged {
            fileTypes.append(.unstaged)
        }
        if untracked {
            fileTypes.append(.untracked)
        }

        let paths = Env.current.git.listFiles(fileTypes)

        guard !paths.isEmpty,
            let rootDirectory = Env.current.git.rootDirectory else {
            Env.current.shell.write("No relevant files found.")
            return false
        }

        let dataSource = GenericLineSelectorDataSource(items: paths)
        let filePaths = LineSelector(dataSource: dataSource)?.multiSelection()?.output.map { "\(rootDirectory)/\($0)" } ?? []

        switch mode {
        case .add:
            return Env.current.git.add(filePaths)
        case .remove:
            var directoryPaths = Set<String>()

            for filePath in filePaths {
                guard FileManager.default.fileExists(atPath: filePath) else {
                    Env.current.shell.write("No file or directory at path \(filePath).")
                    continue
                }

                guard removeItem(at: filePath) else { continue }

                let potentialEmptyDirectoryPath = URL(fileURLWithPath: filePath).deletingLastPathComponent().path
                directoryPaths.insert(potentialEmptyDirectoryPath)
            }

            for directoryPath in directoryPaths {
                var isDirectory = ObjCBool(false)
                let exists = FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory)
                guard isDirectory.boolValue, exists else { continue }

                let contents: [String]
                do {
                    contents = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
                } catch {
                    Env.current.shell.write("\(error)")
                    continue
                }
                guard contents.isEmpty, removeItem(at: directoryPath) else { continue }
            }

            return true
        }
    }

    private func removeItem(at path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        Env.current.shell.write("Removed: \(path)")
        return true
    }
}
