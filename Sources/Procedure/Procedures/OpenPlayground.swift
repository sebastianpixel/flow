import Environment
import Utils

public struct OpenPlayground: Procedure {
    public init() {}

    public func run() -> Bool {
        do {
            let path = Path.temp(isDirectory: false).extending(with: ".playground/")
            let dir = try Env.current.directory.init(path: path) { directory in
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
            return Env.current.workspace.open(dir.path.url)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
    }
}
