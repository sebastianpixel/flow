import AppKit

public protocol Clipboard {
    var string: String? { get set }
}

struct ClipboardImpl: Clipboard {
    var string: String? {
        get {
            return NSPasteboard.general.string(forType: .string)
        }
        set {
            if let newValue = newValue {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(newValue, forType: .string)
            }
        }
    }
}
