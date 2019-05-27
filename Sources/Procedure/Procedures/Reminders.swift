import CommandLineKit
import Environment
import EventKit
import Foundation
import UI
import Utils
import Yams

private extension EKReminder {
    var info: Reminders.Info? {
        return notes.flatMap { try? Reminders.yamlDecoder.decode(from: $0) }
    }
}

public struct Reminders: Procedure {
    enum Action: String, CustomStringConvertible, CaseIterable {
        case add, complete, edit, remove, quit, defaultCalendar

        var shortcut: Character {
            return rawValue.first!
        }

        var description: String {
            let desc: String
            switch self {
            case .add: desc = "add new reminders"
            case .defaultCalendar: desc = "change default calendar"
            case .edit: desc = "edit reminder"
            case .complete: desc = "mark reminders as completed"
            case .remove: desc = "remove reminders"
            case .quit: desc = "quit \(Env.current.toolName)"
            }
            return "(\(shortcut)) \(desc)"
        }
    }

    struct Info: Codable {
        let repository: String?
        let branch: String?
    }

    public enum Scope {
        case branch, repo, all
    }

    private let scope: Scope
    private let lineReader: LineReader
    private let remindersToAdd: [String]

    private static let yamlEncoder = YAMLEncoder()
    fileprivate static let yamlDecoder = YAMLDecoder()

    public init(scope: Scope, remindersToAdd: [String]) {
        guard let lineReader = LineReader() else { fatalError("Could not create LineReader") }
        self.lineReader = lineReader
        self.scope = scope
        self.remindersToAdd = remindersToAdd
    }

    public func run() -> Bool {
        let store = EKEventStore()

        let (success, error) = Future<(Bool, Error?)>({ resolver in
            store.requestAccess(to: .reminder) { success, error in
                resolver((success, error))
            }
        }).await()

        if let error = error, Env.current.debug {
            Env.current.shell.write("\(error)")
        }

        guard success else { return false }

        guard let calendar = (Env.current.defaults[.calendarForReminders] as String?)
            .flatMap(store.calendar(withIdentifier:)) ?? {
                Env.current.shell.write("Please select a calendar (can be changed later):")
                defer { LineDrawer(linesToDrawCount: 1).reset() }
                return changeCalendar(store: store)
            }() else { return false }

        if !remindersToAdd.isEmpty {
            let comma = CharacterSet(charactersIn: ",")
            let titles = remindersToAdd.joined(separator: " ").components(separatedBy: comma).map { $0.trimmingCharacters(in: .whitespaces) }
            guard add(titles: titles, store: store, calendar: calendar, lineDrawer: .init(linesToDrawCount: 0)) else {
                return false
            }
        }

        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)

        guard let reminders = Future<[EKReminder]?>({ resolver in
            store.fetchReminders(matching: predicate) { reminders in
                var filtered: [EKReminder]?
                switch self.scope {
                case .branch:
                    let currentBranch = Env.current.git.currentBranch
                    filtered = reminders?.filter { $0.info?.branch == currentBranch }
                case .repo:
                    let currentRepo = Env.current.git.currentRepo
                    filtered = reminders?.filter { $0.info?.repository == currentRepo }
                case .all:
                    filtered = reminders
                }
                resolver(filtered)
            }
        }).await() else { return false }

        if reminders.isEmpty {
            Env.current.shell.write("Everything done! No open reminders. \\o/")
        }

        let initialLines = [""] + reminders.map { "  \(createLine(for: $0))" } + [""]

        let lineDrawer = LineDrawer(linesToDrawCount: initialLines.count)
        lineDrawer.drawLines(initialLines)

        let remindersDataSource = GenericLineSelectorDataSource(items: reminders, line: createLine)

        let actionItems = Reminders.Action.allCases.sorted { $0.rawValue < $1.rawValue }
        let actions = GenericLineSelectorDataSource(items: actionItems, line: \.description)
        guard let (input, output) = LineSelector(dataSource: actions)?.singleSelection(),
            let action = Reminders.Action.allCases.first(where: { String($0.shortcut) == input }) ?? output else { return true }

        lineDrawer.reset()

        switch action {
        case .add:
            let titles = promptTitlesToAdd()
            return add(titles: titles,
                       store: store,
                       calendar: calendar,
                       lineDrawer: lineDrawer)
        case .defaultCalendar:
            return changeCalendar(store: store) != nil

        case .complete, .remove:
            return completeOrRemove(action: action,
                                    store: store,
                                    remindersDataSource: remindersDataSource,
                                    lineDrawer: lineDrawer)
        case .edit:
            return edit(store: store,
                        remindersDataSource: remindersDataSource,
                        lineDrawer: lineDrawer)
        case .quit:
            return true
        }
    }

    private func completeOrRemove(action: Action, store: EKEventStore, remindersDataSource: GenericLineSelectorDataSource<EKReminder>, lineDrawer: LineDrawer) -> Bool {
        Env.current.shell.write("")
        guard let relevantReminders = LineSelector(dataSource: remindersDataSource)?.multiSelection()?.output,
            !relevantReminders.isEmpty else { return true }
        relevantReminders.forEach { reminder in
            do {
                if action == .remove {
                    try store.remove(reminder, commit: false)
                } else {
                    reminder.isCompleted = true
                    reminder.completionDate = .init()
                    try store.save(reminder, commit: false)
                }
            } catch {
                Env.current.shell.write("\(error)")
            }
        }
        do {
            try store.commit()
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        lineDrawer.reset(lines: 3)
        let titles = relevantReminders.map { "\"\($0.title ?? "")\"" }.joined(separator: ", ")
        let output = action == .complete
            ? "Marked \(titles) as completed."
            : "Removed \(titles)."
        Env.current.shell.write(output)
        return true
    }

    private func edit(store: EKEventStore, remindersDataSource: GenericLineSelectorDataSource<EKReminder>, lineDrawer: LineDrawer) -> Bool {
        Env.current.shell.write("")
        guard let reminder = LineSelector(dataSource: remindersDataSource)?.singleSelection()?.output,
            let newTitle = try? lineReader.readLine(prompt: "Edit reminder: ", line: reminder.title),
            !newTitle.isEmpty else { return true }
        reminder.title = newTitle
        do {
            try store.save(reminder, commit: true)
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }
        lineDrawer.reset(lines: 3)
        Env.current.shell.write("Updated \"\(newTitle)\".")
        return true
    }

    private func promptTitlesToAdd() -> [String] {
        return (try? lineReader
            .readLine(prompt: "Add new reminders (comma separated): ")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }) ?? []
    }

    private func add(titles: [String], store: EKEventStore, calendar: EKCalendar, lineDrawer: LineDrawer) -> Bool {
        guard !titles.isEmpty else { return false }

        let info = Reminders.Info(repository: Env.current.git.currentRepo,
                                  branch: Env.current.git.currentBranch)

        for title in titles {
            let reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
            reminder.title = title
            reminder.notes = try? Reminders.yamlEncoder.encode(info)
            do {
                try store.save(reminder, commit: false)
            } catch {
                Env.current.shell.write("\(error)")
            }
        }
        do {
            try store.commit()
        } catch {
            Env.current.shell.write("\(error)")
        }
        lineDrawer.reset(lines: 1)
        Env.current.shell.write("Added \(titles.map { "\"\($0)\"" }.joined(separator: ", ")).")

        return true
    }

    private var repoCache = Env.current.git.currentRepo
    private var branchCache = Env.current.git.currentBranch

    private func createLine(for reminder: EKReminder) -> String {
        if let info = reminder.info {
            var line = [String]()
            if let repository = info.repository,
                repository != repoCache {
                line.append("repo: \(repository)")
            }
            if let branch = info.branch,
                branch != branchCache {
                line.append("branch: \(branch)")
            }
            return "\(reminder.title ?? "")\(line.isEmpty ? "" : " (\(line.joined(separator: ", ")))")"
        }
        return reminder.title
    }

    private func changeCalendar(store: EKEventStore) -> EKCalendar? {
        let calendars = store.calendars(for: .reminder)
        let dataSource = GenericLineSelectorDataSource(items: calendars) { calendar in
            "\(calendar.title), Source: \(calendar.source.title)"
        }
        let calendar = LineSelector(dataSource: dataSource)?.singleSelection()?.output
        Env.current.defaults[.calendarForReminders] = calendar?.calendarIdentifier
        return calendar
    }
}
