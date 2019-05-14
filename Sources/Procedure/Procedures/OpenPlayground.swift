import Environment
import Utils

public struct OpenPlayground: Procedure {
    public init() {}

    public func run() -> Bool {
        do {
            let path = Env.current.directory.tempPath().removingIfNeeded(suffix: "/").appending(".playground/")
            let dir = try Env.current.directory.init(path: path) {
                try $0.file("Contents.swift") {
                    """
                    import UIKit

                    """
                }
                try $0.file("contents.xcplayground") {
                    """
                    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                    <playground version='5.0' target-platform='ios' executeOnSourceChanges='false'>
                    <timeline fileName='timeline.xctimeline'/>
                    </playground>
                    """
                }
                try $0.file("timeline.xctimeline") {
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
