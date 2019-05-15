import Environment
import Foundation

public struct XCOpen: Procedure {
    public init() {}

    public func run() -> Bool {
        let files: [String]
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath)
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
