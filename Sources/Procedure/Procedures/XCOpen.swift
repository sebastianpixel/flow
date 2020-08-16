import Environment
import Foundation

public struct XCOpen: Procedure {
    private let path: String

    public init(path: String?) {
        let currentDirectory = FileManager.default.currentDirectoryPath
        if let path = path, path.starts(with: ".") {
            self.path = currentDirectory + path.dropFirst()
        } else {
            self.path = path ?? currentDirectory
        }
    }

    public func run() -> Bool {
        if Env.current.debug {
            Env.current.shell.write("\(path)")
        }

        if path.range(of: "\\.(xcodeproj|xcworkspace|playground)$", options: .regularExpression) != nil {
            return Env.current.workspace.openFile(path)
        }

        let files: [String]
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }

        let relevantFileEndings = ["xcworkspace", "xcodeproj", "playground"]

        for ending in relevantFileEndings {
            if let file = files.first(where: { $0.hasSuffix(ending) }) {
                return Env.current.workspace.openFile(file)
            }
        }

        Env.current.shell.write("No file found ending with \(relevantFileEndings.joined(separator: ", ")).")

        return false
    }
}
