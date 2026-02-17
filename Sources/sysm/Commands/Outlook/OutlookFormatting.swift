import SysmCore

enum OutlookFormatting {
    static func printMessages(_ messages: [OutlookMessage], header: String, emptyMessage: String) {
        if messages.isEmpty {
            print(emptyMessage)
            return
        }

        print("\(header) (\(messages.count)):")
        for msg in messages {
            let prefix = msg.isRead ? " " : "*"
            print("\n  \(prefix)[\(msg.id)] \(msg.subject)")
            print("   From: \(msg.from)")
            print("   Date: \(msg.dateReceived)")
        }
        if messages.contains(where: { !$0.isRead }) {
            print("\n  (* = unread)")
        }
    }
}
