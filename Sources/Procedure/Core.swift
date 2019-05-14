import Environment
import Foundation

public struct Core {
    public init(debug: Bool, toolName: String) {
        Env.current.debug = debug
        Env.current.toolName = toolName
    }

    public func run(_ procedure: Procedure) {
        if !procedure.run() {
            exit(EXIT_FAILURE)
        }
    }
}
