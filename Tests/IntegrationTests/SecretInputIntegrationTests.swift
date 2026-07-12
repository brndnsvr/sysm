import Foundation
import PDFKit
import XCTest

final class SecretInputIntegrationTests: IntegrationTestCase {
    func testSecureOptionsReplaceEverySecretBearingValueOption() throws {
        let expectations: [([String], [String], [String])] = [
            (["slack", "auth", "--help"], ["--configure", "--token-stdin", "--token-fd"], ["--token <"]),
            (["pdf", "decrypt", "--help"], ["--password-stdin", "--password-fd"], ["--password <"]),
            (
                ["pdf", "encrypt", "--help"],
                ["--owner-password-stdin", "--owner-password-fd", "--user-password-prompt", "--user-password-stdin", "--user-password-fd"],
                ["--owner-password <", "--user-password <"]
            ),
            (["keychain", "set", "--help"], ["--value-stdin", "--value-fd"], ["--value <"]),
            (
                ["calendar", "caldav-auth", "--help"],
                ["--configure", "--app-password-stdin", "--app-password-fd"],
                ["--app-password <"]
            ),
        ]

        for (arguments, secureOptions, unsafeOptions) in expectations {
            let help = try runCommand(arguments)
            for option in secureOptions {
                XCTAssertTrue(help.contains(option), "Missing \(option) in \(arguments)")
            }
            for option in unsafeOptions {
                XCTAssertFalse(help.contains(option), "Unsafe option \(option) remains in \(arguments)")
            }
        }
    }

    func testLegacySecretValuesAreNotReflectedInDiagnostics() throws {
        let sentinel = "DO_NOT_REFLECT_SECRET_7Q9"
        let invocations: [[String]] = [
            ["slack", "auth", "--token", sentinel],
            ["pdf", "decrypt", "input.pdf", "--password", sentinel, "--output", "out.pdf"],
            ["pdf", "encrypt", "input.pdf", "--owner-password", sentinel, "--output", "out.pdf"],
            ["pdf", "encrypt", "input.pdf", "--user-password", sentinel, "--output", "out.pdf"],
            ["keychain", "set", "service", "account", "--value", sentinel],
            ["calendar", "caldav-auth", "--apple-id", "test@example.com", "--app-password", sentinel],
        ]

        for arguments in invocations {
            do {
                _ = try runCommand(arguments)
                XCTFail("Legacy invocation should fail: \(arguments.first ?? "unknown")")
            } catch IntegrationTestError.commandFailed(_, _, let stderr) {
                XCTAssertFalse(stderr.contains(sentinel), "Diagnostic reflected the supplied secret")
            }
        }
    }

    func testStatusPathsDoNotRequireSecretInput() throws {
        let slackOutput = try runCommand(["slack", "auth", "--status"])
        XCTAssertTrue(slackOutput.contains("Slack:"))

        let caldavOutput = try runCommand(["calendar", "caldav-auth", "--status"])
        XCTAssertTrue(caldavOutput.contains("CalDAV:"))
    }

    func testKeychainStdinSecretIsAbsentFromProcessArgumentsAndRoundTrips() throws {
        let service = "sysm-secret-input-test-\(UUID().uuidString)"
        let account = "integration-test"
        let sentinel = "PROCESS_TABLE_SECRET_7Q9"
        defer {
            _ = try? runCommand(["keychain", "delete", service, account])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = ["keychain", "set", service, account, "--value-stdin"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        XCTAssertTrue(process.isRunning)

        let commandLine = try processCommandLine(pid: process.processIdentifier)
        XCTAssertFalse(commandLine.contains(sentinel))
        XCTAssertTrue(commandLine.contains("--value-stdin"))

        inputPipe.fileHandleForWriting.write(Data("\(sentinel)\n".utf8))
        try inputPipe.fileHandleForWriting.close()
        process.waitUntilExit()

        let stderr = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        XCTAssertEqual(process.terminationStatus, 0, stderr)
        XCTAssertFalse(stderr.contains(sentinel))

        let stored = try runCommand(["keychain", "get", service, account])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(stored, sentinel)
    }

    func testPDFOwnerAndDecryptPasswordsRoundTripThroughStdin() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-secret-pdf-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let input = tempDirectory.appendingPathComponent("input.pdf")
        let encrypted = tempDirectory.appendingPathComponent("encrypted.pdf")
        let decrypted = tempDirectory.appendingPathComponent("decrypted.pdf")
        let password = "PDF_SECRET_7Q9"

        let document = PDFDocument()
        document.insert(PDFPage(), at: 0)
        XCTAssertTrue(document.write(to: input))

        _ = try runCommand(
            [
                "pdf", "encrypt", input.path,
                "--owner-password-stdin",
                "--output", encrypted.path,
            ],
            standardInput: Data("\(password)\n".utf8)
        )

        let encryptedDocument = try XCTUnwrap(PDFDocument(url: encrypted))
        XCTAssertTrue(encryptedDocument.isEncrypted)

        _ = try runCommand(
            [
                "pdf", "decrypt", encrypted.path,
                "--password-stdin",
                "--output", decrypted.path,
            ],
            standardInput: Data("\(password)\n".utf8)
        )

        let decryptedDocument = try XCTUnwrap(PDFDocument(url: decrypted))
        XCTAssertEqual(decryptedDocument.pageCount, 1)
    }

    private func processCommandLine(pid: Int32) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-ww", "-o", "command=", "-p", String(pid)]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw IntegrationTestError.setupFailed("Unable to inspect the disposable child process")
        }
        return String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    }
}
