import XCTest
@testable import SysmCore

/// Codable round-trip tests for miscellaneous models.
final class MiscModelCodableTests: XCTestCase {

    // MARK: - AppStoreApp

    func testAppStoreAppCodable() throws {
        let app = AppStoreApp(id: "123", name: "TestApp", version: "1.2.3")
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AppStoreApp.self, from: data)
        XCTAssertEqual(decoded.id, "123")
        XCTAssertEqual(decoded.name, "TestApp")
        XCTAssertEqual(decoded.version, "1.2.3")
    }

    func testAppStoreAppNilVersion() throws {
        let app = AppStoreApp(id: "456", name: "Another")
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AppStoreApp.self, from: data)
        XCTAssertNil(decoded.version)
    }

    // MARK: - BluetoothStatus

    func testBluetoothStatusCodable() throws {
        let status = BluetoothStatus(powered: true, discoverable: false, address: "AA:BB:CC:DD:EE:FF")
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(BluetoothStatus.self, from: data)
        XCTAssertTrue(decoded.powered)
        XCTAssertFalse(decoded.discoverable)
        XCTAssertEqual(decoded.address, "AA:BB:CC:DD:EE:FF")
    }

    // MARK: - BluetoothDevice

    func testBluetoothDeviceCodable() throws {
        let device = BluetoothDevice(name: "AirPods Pro", address: "11:22:33:44:55:66", connected: true, paired: true, deviceType: "headphones")
        let data = try JSONEncoder().encode(device)
        let decoded = try JSONDecoder().decode(BluetoothDevice.self, from: data)
        XCTAssertEqual(decoded.name, "AirPods Pro")
        XCTAssertTrue(decoded.connected)
        XCTAssertEqual(decoded.deviceType, "headphones")
    }

    // MARK: - VolumeInfo (Disk)

    func testVolumeInfoCodable() throws {
        let vol = VolumeInfo(
            name: "Macintosh HD", mountPoint: "/", fileSystem: "APFS",
            totalSize: 500_000_000_000, totalSizeFormatted: "500 GB",
            freeSpace: 200_000_000_000, freeSpaceFormatted: "200 GB",
            usedSpace: 300_000_000_000, usedSpaceFormatted: "300 GB",
            usedPercent: 60.0, isRemovable: false, isInternal: true
        )
        let data = try JSONEncoder().encode(vol)
        let decoded = try JSONDecoder().decode(VolumeInfo.self, from: data)
        XCTAssertEqual(decoded.name, "Macintosh HD")
        XCTAssertEqual(decoded.totalSize, 500_000_000_000)
        XCTAssertEqual(decoded.usedPercent, 60.0)
        XCTAssertTrue(decoded.isInternal)
    }

    // MARK: - DirectorySize

    func testDirectorySizeCodable() throws {
        let dir = DirectorySize(path: "/Users/test", size: 1_000_000, sizeFormatted: "1 MB", fileCount: 42)
        let data = try JSONEncoder().encode(dir)
        let decoded = try JSONDecoder().decode(DirectorySize.self, from: data)
        XCTAssertEqual(decoded.path, "/Users/test")
        XCTAssertEqual(decoded.fileCount, 42)
    }

    // MARK: - NetworkStatus

    func testNetworkStatusCodable() throws {
        let status = NetworkStatus(connected: true, interfaces: ["en0", "en1"], primaryInterface: "en0", externalIP: "1.2.3.4")
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(NetworkStatus.self, from: data)
        XCTAssertTrue(decoded.connected)
        XCTAssertEqual(decoded.interfaces, ["en0", "en1"])
        XCTAssertEqual(decoded.externalIP, "1.2.3.4")
    }

    // MARK: - WiFiInfo

    func testWiFiInfoCodable() throws {
        let wifi = WiFiInfo(ssid: "MyNetwork", bssid: "AA:BB:CC:DD:EE:FF", channel: 36, rssi: -45, noise: -90, security: "WPA3")
        let data = try JSONEncoder().encode(wifi)
        let decoded = try JSONDecoder().decode(WiFiInfo.self, from: data)
        XCTAssertEqual(decoded.ssid, "MyNetwork")
        XCTAssertEqual(decoded.channel, 36)
        XCTAssertEqual(decoded.security, "WPA3")
    }

    // MARK: - PingResult

    func testPingResultCodable() throws {
        let ping = PingResult(host: "google.com", packetsTransmitted: 4, packetsReceived: 4, packetLoss: 0.0,
                              roundTripMin: 1.5, roundTripAvg: 2.3, roundTripMax: 3.1)
        let data = try JSONEncoder().encode(ping)
        let decoded = try JSONDecoder().decode(PingResult.self, from: data)
        XCTAssertEqual(decoded.host, "google.com")
        XCTAssertEqual(decoded.packetLoss, 0.0)
        XCTAssertEqual(decoded.roundTripAvg, 2.3)
    }

    // MARK: - PendingNotification

    func testPendingNotificationCodable() throws {
        let notif = PendingNotification(identifier: "notif-1", title: "Reminder", body: "Don't forget",
                                         subtitle: "Important", triggerDate: Date(timeIntervalSince1970: 1705312800))
        let data = try JSONEncoder().encode(notif)
        let decoded = try JSONDecoder().decode(PendingNotification.self, from: data)
        XCTAssertEqual(decoded.identifier, "notif-1")
        XCTAssertEqual(decoded.title, "Reminder")
        XCTAssertEqual(decoded.subtitle, "Important")
    }

    // MARK: - PodcastShow

    func testPodcastShowCodable() throws {
        let show = PodcastShow(name: "Tech Talk", episodeCount: 150, author: "Host Name")
        let data = try JSONEncoder().encode(show)
        let decoded = try JSONDecoder().decode(PodcastShow.self, from: data)
        XCTAssertEqual(decoded.name, "Tech Talk")
        XCTAssertEqual(decoded.episodeCount, 150)
    }

    // MARK: - PodcastEpisode

    func testPodcastEpisodeCodable() throws {
        let ep = PodcastEpisode(title: "Episode 1", showName: "Tech Talk", date: "Jan 15", duration: "45 min", played: false)
        let data = try JSONEncoder().encode(ep)
        let decoded = try JSONDecoder().decode(PodcastEpisode.self, from: data)
        XCTAssertEqual(decoded.title, "Episode 1")
        XCTAssertEqual(decoded.played, false)
    }

    // MARK: - BookInfo

    func testBookInfoCodable() throws {
        let book = BookInfo(title: "Swift Programming", author: "Apple", path: "/Books/swift.epub")
        let data = try JSONEncoder().encode(book)
        let decoded = try JSONDecoder().decode(BookInfo.self, from: data)
        XCTAssertEqual(decoded.title, "Swift Programming")
        XCTAssertEqual(decoded.author, "Apple")
    }

    // MARK: - BookCollection

    func testBookCollectionCodable() throws {
        let collection = BookCollection(name: "Want to Read", bookCount: 12)
        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(BookCollection.self, from: data)
        XCTAssertEqual(decoded.name, "Want to Read")
        XCTAssertEqual(decoded.bookCount, 12)
    }

    // MARK: - FileInfo

    func testFileInfoCodable() throws {
        let file = FileInfo(path: "/Users/test/doc.txt", name: "doc.txt", kind: "text",
                           size: 1024, sizeFormatted: "1 KB", created: Date(), modified: Date(),
                           isDirectory: false, isHidden: false)
        let data = try JSONEncoder().encode(file)
        let decoded = try JSONDecoder().decode(FileInfo.self, from: data)
        XCTAssertEqual(decoded.name, "doc.txt")
        XCTAssertEqual(decoded.size, 1024)
        XCTAssertFalse(decoded.isDirectory)
    }

    // MARK: - VoiceInfo

    func testVoiceInfoCodable() throws {
        let voice = VoiceInfo(name: "Samantha", language: "en-US", identifier: "com.apple.voice.compact.en-US.Samantha")
        let data = try JSONEncoder().encode(voice)
        let decoded = try JSONDecoder().decode(VoiceInfo.self, from: data)
        XCTAssertEqual(decoded.name, "Samantha")
        XCTAssertEqual(decoded.language, "en-US")
    }

    // MARK: - TimeMachineStatus

    func testTimeMachineStatusCodable() throws {
        let status = TimeMachineStatus(running: true, phase: "Copying", progress: 0.45, destination: "/Volumes/Backup")
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(TimeMachineStatus.self, from: data)
        XCTAssertTrue(decoded.running)
        XCTAssertEqual(decoded.phase, "Copying")
        XCTAssertEqual(decoded.progress, 0.45)
    }

    // MARK: - TimeMachineBackup

    func testTimeMachineBackupCodable() throws {
        let backup = TimeMachineBackup(date: "2024-01-15", path: "/Volumes/Backup/2024-01-15")
        let data = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(TimeMachineBackup.self, from: data)
        XCTAssertEqual(decoded.date, "2024-01-15")
    }

    // MARK: - SlackChannel

    func testSlackChannelCodable() throws {
        let channel = SlackChannel(id: "C123", name: "general", isPrivate: false, memberCount: 50, topic: "General discussion")
        let data = try JSONEncoder().encode(channel)
        let decoded = try JSONDecoder().decode(SlackChannel.self, from: data)
        XCTAssertEqual(decoded.id, "C123")
        XCTAssertEqual(decoded.name, "general")
        XCTAssertFalse(decoded.isPrivate)
        XCTAssertEqual(decoded.memberCount, 50)
    }

    // MARK: - SlackMessageResult

    func testSlackMessageResultCodable() throws {
        let result = SlackMessageResult(channel: "C123", timestamp: "1705312800.123456", ok: true)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(SlackMessageResult.self, from: data)
        XCTAssertEqual(decoded.channel, "C123")
        XCTAssertTrue(decoded.ok)
    }

    // MARK: - NetworkInterface

    func testNetworkInterfaceCodable() throws {
        let iface = NetworkInterface(name: "en0", ipAddress: "192.168.1.100", macAddress: "AA:BB:CC:DD:EE:FF", status: "active")
        let data = try JSONEncoder().encode(iface)
        let decoded = try JSONDecoder().decode(NetworkInterface.self, from: data)
        XCTAssertEqual(decoded.name, "en0")
        XCTAssertEqual(decoded.status, "active")
    }

    // MARK: - WiFiNetwork

    func testWiFiNetworkCodable() throws {
        let network = WiFiNetwork(ssid: "CoffeeShop", bssid: nil, rssi: -60, channel: 6, security: "WPA2")
        let data = try JSONEncoder().encode(network)
        let decoded = try JSONDecoder().decode(WiFiNetwork.self, from: data)
        XCTAssertEqual(decoded.ssid, "CoffeeShop")
        XCTAssertNil(decoded.bssid)
    }

    // MARK: - Conversation (Messages)

    func testConversationCodable() throws {
        let conv = Conversation(id: "chat-1", name: "Family", participants: "+1234567890, +0987654321")
        let data = try JSONEncoder().encode(conv)
        let decoded = try JSONDecoder().decode(Conversation.self, from: data)
        XCTAssertEqual(decoded.id, "chat-1")
        XCTAssertEqual(decoded.name, "Family")
    }

    // MARK: - Message (Messages)

    func testMessageCodable() throws {
        let msg = Message(date: "Jan 15, 2024", sender: "+1234567890", content: "Hello!")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(Message.self, from: data)
        XCTAssertEqual(decoded.content, "Hello!")
    }
}
