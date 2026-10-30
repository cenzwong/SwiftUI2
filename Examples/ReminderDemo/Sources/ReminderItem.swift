import Foundation

public struct ReminderItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var dueDateExpression: String?
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, dueDateExpression: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.dueDateExpression = dueDateExpression
        self.isCompleted = isCompleted
    }
}

@MainActor
public final class ReminderRepository: ObservableObject {
    @Published public private(set) var items: [ReminderItem] = [
        ReminderItem(title: "Buy milk", dueDateExpression: "Tomorrow", isCompleted: false),
        ReminderItem(title: "Meeting with John", dueDateExpression: "Friday at 4pm", isCompleted: false)
    ]

    public init() {}

    public func add(title: String, dueDateExpression: String? = nil) {
        let item = ReminderItem(title: title, dueDateExpression: dueDateExpression)
        items.append(item)
    }

    public func update(targetTitle: String, newTitle: String? = nil, newDueDateExpression: String? = nil) -> Bool {
        guard let index = items.firstIndex(where: { $0.title.localizedCaseInsensitiveContains(targetTitle) }) else {
            return false
        }
        if let newTitle = newTitle, !newTitle.isEmpty {
            items[index].title = newTitle
        }
        if let newDueDateExpression = newDueDateExpression {
            items[index].dueDateExpression = newDueDateExpression
        }
        return true
    }

    public func complete(targetTitle: String) -> Bool {
        guard let index = items.firstIndex(where: { $0.title.localizedCaseInsensitiveContains(targetTitle) }) else {
            return false
        }
        items[index].isCompleted = true
        return true
    }

    public func toggleCompletion(for id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isCompleted.toggle()
        }
    }
}
