import Foundation
import XCTest

@testable import sysm
import SysmCore

final class SecureCommandHandoffTests: XCTestCase {
    func testSlackTokenUsesSecureReaderAndServiceProtocol() throws {
        let command = try SlackAuth.parse(["--token-stdin"])
        let reader = StubSecretInputReader(values: [.standardInput: "xoxb-test-token"])
        let service = RecordingSlackService()

        try command.run(service: service, secretReader: reader)

        XCTAssertEqual(reader.sources, [.standardInput])
        XCTAssertEqual(service.savedToken, "xoxb-test-token")
    }

    func testSlackStatusDoesNotReadSecretInput() throws {
        let command = try SlackAuth.parse(["--status"])
        let reader = StubSecretInputReader(values: [:])
        let service = RecordingSlackService()

        try command.run(service: service, secretReader: reader)

        XCTAssertTrue(reader.sources.isEmpty)
        XCTAssertNil(service.savedToken)
    }

    func testPDFDecryptPassesStdinPasswordToService() throws {
        let command = try PDFDecrypt.parse([
            "input.pdf", "--password-stdin", "--output", "output.pdf",
        ])
        let reader = StubSecretInputReader(values: [.standardInput: "decrypt-secret"])
        let service = RecordingPDFService()

        try command.run(service: service, secretReader: reader)

        XCTAssertEqual(service.decryptCall?.password, "decrypt-secret")
        XCTAssertEqual(service.decryptCall?.input, "input.pdf")
        XCTAssertEqual(service.decryptCall?.output, "output.pdf")
    }

    func testPDFEncryptUsesIndependentOwnerAndUserSources() throws {
        let command = try PDFEncrypt.parse([
            "input.pdf",
            "--owner-password-stdin",
            "--user-password-fd", "4",
            "--output", "output.pdf",
        ])
        let reader = StubSecretInputReader(values: [
            .standardInput: "owner-secret",
            .fileDescriptor(4): "user-secret",
        ])
        let service = RecordingPDFService()

        try command.run(service: service, secretReader: reader)

        XCTAssertEqual(reader.sources, [.standardInput, .fileDescriptor(4)])
        XCTAssertEqual(service.encryptCall?.ownerPassword, "owner-secret")
        XCTAssertEqual(service.encryptCall?.userPassword, "user-secret")
    }

    func testKeychainValueUsesSecureReaderAndServiceProtocol() throws {
        let command = try KeychainSet.parse([
            "service", "account", "--value-fd", "5", "--label", "label",
        ])
        let reader = StubSecretInputReader(values: [.fileDescriptor(5): "stored-secret"])
        let service = RecordingKeychainService()

        try command.run(service: service, secretReader: reader)

        XCTAssertEqual(service.setCall?.service, "service")
        XCTAssertEqual(service.setCall?.account, "account")
        XCTAssertEqual(service.setCall?.value, "stored-secret")
        XCTAssertEqual(service.setCall?.label, "label")
    }

    func testCalDAVPasswordUsesSecureReaderAndServiceProtocol() throws {
        let command = try CalendarCaldavAuth.parse([
            "--apple-id", "test@example.com", "--app-password-fd", "6",
        ])
        let reader = StubSecretInputReader(values: [.fileDescriptor(6): "app-password"])
        let service = RecordingCalDAVService()

        try command.run(service: service, secretReader: reader)

        XCTAssertEqual(service.credentials?.appleID, "test@example.com")
        XCTAssertEqual(service.credentials?.appPassword, "app-password")
    }

    func testPDFEncryptRejectsTwoStdinConsumers() {
        XCTAssertThrowsError(
            try PDFEncrypt.parse([
                "input.pdf",
                "--owner-password-stdin",
                "--user-password-stdin",
                "--output", "output.pdf",
            ])
        )
    }

    func testPDFEncryptRejectsSharedFileDescriptor() {
        XCTAssertThrowsError(
            try PDFEncrypt.parse([
                "input.pdf",
                "--owner-password-fd", "4",
                "--user-password-fd", "4",
                "--output", "output.pdf",
            ])
        )
    }

    func testCalDAVStatusDoesNotReadSecretInput() throws {
        let command = try CalendarCaldavAuth.parse(["--status"])
        let reader = StubSecretInputReader(values: [:])
        let service = RecordingCalDAVService()

        try command.run(service: service, secretReader: reader)

        XCTAssertTrue(reader.sources.isEmpty)
        XCTAssertNil(service.credentials)
    }
}

private final class StubSecretInputReader: SecretInputReading, @unchecked Sendable {
    private let values: [SecretInputSource: String]
    private(set) var sources: [SecretInputSource] = []

    init(values: [SecretInputSource: String]) {
        self.values = values
    }

    func read(
        from source: SecretInputSource,
        prompt: String,
        maximumBytes: Int
    ) throws -> String {
        sources.append(source)
        guard let value = values[source] else {
            throw SecretInputError.emptyInput
        }
        return value
    }
}

private final class RecordingSlackService: SlackServiceProtocol, @unchecked Sendable {
    var configured = false
    var savedToken: String?
    var removed = false

    func isConfigured() -> Bool { configured }
    func setToken(_ token: String) throws { savedToken = token }
    func removeToken() throws { removed = true }
    func sendMessage(channel: String, text: String) async throws -> SlackMessageResult {
        fatalError("Unused in secure command tests")
    }
    func setStatus(text: String, emoji: String?) async throws {
        fatalError("Unused in secure command tests")
    }
    func listChannels(limit: Int) async throws -> [SlackChannel] {
        fatalError("Unused in secure command tests")
    }
}

private final class RecordingPDFService: PDFServiceProtocol, @unchecked Sendable {
    var encryptCall: (input: String, ownerPassword: String, userPassword: String?, output: String)?
    var decryptCall: (input: String, password: String, output: String)?

    func encrypt(path: String, ownerPassword: String, userPassword: String?, outputPath: String) throws {
        encryptCall = (path, ownerPassword, userPassword, outputPath)
    }

    func decrypt(path: String, password: String, outputPath: String) throws {
        decryptCall = (path, password, outputPath)
    }

    func info(path: String) throws -> PDFInfo { fatalError("Unused") }
    func text(path: String, page: Int?) throws -> String { fatalError("Unused") }
    func search(path: String, query: String, caseSensitive: Bool) throws -> [PDFSearchResult] { fatalError("Unused") }
    func pages(path: String) throws -> [PDFPageInfo] { fatalError("Unused") }
    func thumbnail(path: String, page: Int, outputPath: String, size: Int) throws { fatalError("Unused") }
    func merge(paths: [String], outputPath: String) throws { fatalError("Unused") }
    func split(path: String, pageRange: ClosedRange<Int>, outputPath: String) throws { fatalError("Unused") }
    func rotate(path: String, pages: [Int], angle: Int, outputPath: String) throws { fatalError("Unused") }
    func metadata(path: String) throws -> PDFInfo { fatalError("Unused") }
    func setMetadata(path: String, title: String?, author: String?, subject: String?, keywords: [String]?, outputPath: String) throws { fatalError("Unused") }
    func annotations(path: String, page: Int?) throws -> [PDFAnnotationInfo] { fatalError("Unused") }
    func addAnnotation(path: String, page: Int, type: String, text: String, x: Double, y: Double, outputPath: String) throws { fatalError("Unused") }
    func watermark(path: String, text: String, fontSize: Double, opacity: Double, angle: Double, outputPath: String) throws { fatalError("Unused") }
    func compress(path: String, outputPath: String) throws { fatalError("Unused") }
    func ocrEmbed(path: String, outputPath: String) throws { fatalError("Unused") }
    func imagesToPDF(imagePaths: [String], outputPath: String) throws { fatalError("Unused") }
    func outline(path: String) throws -> [PDFOutlineEntry] { fatalError("Unused") }
    func permissions(path: String) throws -> PDFPermissions { fatalError("Unused") }
}

private final class RecordingKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    var setCall: (service: String, account: String, value: String, label: String?)?

    func set(service: String, account: String, value: String, label: String?) throws {
        setCall = (service, account, value, label)
    }

    func get(service: String, account: String) throws -> KeychainItemDetail { fatalError("Unused") }
    func delete(service: String, account: String) throws { fatalError("Unused") }
    func list(service: String?) throws -> [KeychainItem] { fatalError("Unused") }
    func search(query: String) throws -> [KeychainItem] { fatalError("Unused") }
}

private final class RecordingCalDAVService: CalDAVServiceProtocol, @unchecked Sendable {
    var configured = false
    var credentials: (appleID: String, appPassword: String)?
    var removed = false

    func isConfigured() -> Bool { configured }
    func setCredentials(appleID: String, appPassword: String) throws {
        credentials = (appleID, appPassword)
    }
    func removeCredentials() throws { removed = true }
    func discoverCalendars() async throws -> [CalDAVCalendar] { fatalError("Unused") }
    func addAttendees(emails: [String], toEventUID uid: String, calendarName: String?, organizerEmail: String?) async throws {
        fatalError("Unused")
    }
}
