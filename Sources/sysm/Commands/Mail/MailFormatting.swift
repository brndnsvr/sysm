import SysmCore

enum MailFormatting {
    static func printMessageList(
        _ messages: [MailMessage],
        header: String,
        emptyMessage: String,
        showReadStatus: Bool = true
    ) {
        if messages.isEmpty {
            print(emptyMessage)
            return
        }
        print("\(header) (\(messages.count)):")
        for msg in messages {
            let prefix = showReadStatus ? (msg.isRead ? " " : "*") : " "
            print("\n  \(prefix)[\(msg.id)] \(msg.subject)")
            print("   From: \(msg.from)")
            print("   Date: \(msg.dateReceived)")
        }
        if showReadStatus { print("\n  (* = unread)") }
    }
}
