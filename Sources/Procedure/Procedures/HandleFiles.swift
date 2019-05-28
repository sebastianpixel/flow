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
            var directories = [URL: Set<URL>]()
            var success = true

            for filePath in filePaths {
                guard Env.current.file.init(path: .init(stringLiteral: filePath)).exists else {
                    Env.current.shell.write("No file or directory at path \(filePath).")
                    success = false
                    continue
                }

                let file = URL(fileURLWithPath: filePath)
                let directory = file.deletingLastPathComponent()

                if directories[directory] == nil {
                    directories[directory] = [file]
                } else {
                    directories[directory]?.insert(file)
                }
            }

            for (directory, filesToRemove) in directories {
                let contents: Set<URL>
                do {
                    contents = Set(try Env.current.directory.init(path: .init(stringLiteral: directory.path), create: false).contents())
                } catch {
                    Env.current.shell.write("\(error)")
                    success = false
                    continue
                }
                success = success && contents == filesToRemove ? removeItem(at: directory) : filesToRemove.allSatisfy(removeItem)
            }

            return success
        }
    }

    private func removeItem(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        Env.current.shell.write("Removed: \(url.path)")
        return true
    }
}
