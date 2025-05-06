//
//  ViewController.swift
//  TableViewDemo
//
//  Created by Kela on 2025/5/6.
//

import Cocoa

enum ListItem: Hashable {
    case message(Message)
    case conversation(Conversation)
}

class Message: Hashable {
    let content: String
    init(content: String) {
        self.content = content
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.content == rhs.content
    }
}

class Conversation: Hashable {
    let title: String
    let messages: [Message]
    var isExpanded: Bool = false

    init(title: String, messages: [Message]) {
        self.title = title
        self.messages = messages
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.title == rhs.title
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!

    var conversations: [Conversation] = []
    var expandedConversation: Conversation?
    var displayItems: [ListItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
    }

    func setupData() {
        let conversationCount = 1000
        for i in 0..<conversationCount {
            let messages = [
                Message(content: "Message 1 for Conversation \(i)"),
                Message(content: "Message 2 for Conversation \(i)"),
                Message(content: "Message 3 for Conversation \(i)"),
                Message(content: "Message 4 for Conversation \(i)"),
                Message(content: "Message 5 for Conversation \(i)"),
            ]
            let conversation = Conversation(title: "Conversation \(i)", messages: messages)
            conversations.append(conversation)
        }
        rebuildDisplayItems()
    }

    func rebuildDisplayItems(animation: Bool = false) {
        var newDisplayItems = [ListItem]()
        for convo in conversations {
            newDisplayItems.append(.conversation(convo))
            if convo.isExpanded {
                expandedConversation = convo
                newDisplayItems.append(contentsOf: convo.messages.map { .message($0) })
            }
        }

        if animation {
            var insertIndex: [Int] = []
            var removeIndex: [Int] = []
            for difference in newDisplayItems.difference(from: displayItems) {
                switch difference {
                case .insert(offset: let index, element: _, associatedWith: _):
                    insertIndex.append(index)
                case .remove(offset: let index, element: _, associatedWith: _):
                    removeIndex.append(index)
                }
            }

            displayItems = newDisplayItems

            tableView.beginUpdates()

            tableView.removeRows(at: IndexSet(removeIndex), withAnimation: [.effectFade, .slideUp])
            tableView.insertRows(at: IndexSet(insertIndex), withAnimation: [.effectFade, .slideDown])

            tableView.endUpdates()
        } else {
            displayItems = newDisplayItems
            tableView.reloadData()
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Wait 1s scroll to bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.scrollRowToVisible(self.displayItems.count - 1)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        if let column = tableView.tableColumns.first {
            column.width = view.bounds.width
        }
    }
}

// MARK: - NSTableViewDataSource & Delegate

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = displayItems[row]
        let identifier = NSUserInterfaceItemIdentifier("Cell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? BorderedCellView

        if cell == nil {
            cell = BorderedCellView()
            cell?.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -5),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }

        switch item {
        case .conversation(let conversation):
            cell?.textField?.stringValue = "📁 " + conversation.title
            cell?.textField?.font = NSFont.boldSystemFont(ofSize: 12)
            cell?.isConversation = true
        case .message(let message):
            cell?.textField?.stringValue = "✉️ " + message.content
            cell?.textField?.font = NSFont.systemFont(ofSize: 11)
            cell?.isConversation = false
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = displayItems[row]

        switch item {
        case .conversation(_):
            return 64
        case .message(_):
            return 40
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }

        if case .conversation(let conversation) = displayItems[selectedRow] {
            if expandedConversation?.title == conversation.title {
                conversation.isExpanded.toggle()
            } else {
                expandedConversation?.isExpanded = false
                conversation.isExpanded = true
            }
            rebuildDisplayItems(animation: true)
        }
    }
}

class BorderedCellView: NSTableCellView {
    var isConversation: Bool = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard isConversation else { return }

        // Draw bottom border
        let line = NSBezierPath()
        line.move(to: CGPoint(x: 0, y: 0))
        line.line(to: CGPoint(x: bounds.width, y: 0))
        NSColor.separatorColor.setStroke()
        line.lineWidth = 1
        line.stroke()
    }
}
