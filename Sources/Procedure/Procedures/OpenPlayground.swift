import Environment
import Utils

public struct OpenPlayground: Procedure {
    public init() {}

    public func run() -> Bool {
        do {
            let path = Path.temp.value.removingIfNeeded(suffix: "/").appending(".playground/")
            let dir = try Env.current.directory.init(path: .init(stringLiteral: path)) { directory in
                try directory.file("Contents.swift") {
                    """
                    import UIKit

                    """
                }
                try directory.file("contents.xcplayground") {
                    """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <playground version='5.0' target-platform='ios' executeOnSourceChanges='false'>
                    <timeline fileName='timeline.xctimeline'/>
                    </playground>
                    """
                }
                try directory.file("timeline.xctimeline") {
                    """
                    <?xml version="1.0" encoding="UTF-8"?>
                    <Timeline
                    version = "3.0">
                    <TimelineItems>
                    </TimelineItems>
                    </Timeline>
                    """
                }
            }
            return Env.current.workspace.openFile(dir.path)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
    }
}
