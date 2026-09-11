import XCTest
@testable import SysmCore

/// These tests never create a job: every call either fails validation before
/// touching the filesystem or exercises pure plist serialization.
final class LaunchdServiceTests: XCTestCase {
    private let traversalName = "../../../var/log/system"

    // MARK: - validateJobName(_:)

    func testValidJobNamesAreAccepted() {
        for name in ["backup", "daily-report", "sync_2", "a", "v1.2", "A9", String(repeating: "a", count: 128)] {
            XCTAssertNoThrow(try LaunchdService.validateJobName(name), name)
        }
    }

    func testUnsafeJobNamesAreRejected() {
        let names = [
            "", "..", ".hidden", "-flag", "../../x", traversalName, "a/b",
            "name with space", "tab\tname", "line\nbreak", "trailing\n", "semi;colon",
            "caf\u{E9}", String(repeating: "a", count: 129),
        ]
        for name in names {
            assertInvalidName(try LaunchdService.validateJobName(name), name)
        }
    }

    func testEveryNameTakingEntryPointValidatesFirst() {
        let service = LaunchdService()
        let name = traversalName

        assertInvalidName(try service.getJobLogs(name: name, lines: 5), "getJobLogs")
        assertInvalidName(try service.getJob(name: name), "getJob")
        assertInvalidName(try service.removeJob(name: name), "removeJob")
        assertInvalidName(try service.enableJob(name: name), "enableJob")
        assertInvalidName(try service.disableJob(name: name), "disableJob")
        assertInvalidName(try service.runJobNow(name: name), "runJobNow")
        assertInvalidName(
            try service.createJob(
                name: name, command: "true", cron: nil, interval: 60, runAtLoad: false,
                workingDirectory: nil, env: nil, force: false
            ),
            "createJob"
        )
    }

    // MARK: - buildPlist(...)

    func testPlistKeepsXmlSensitiveValuesIntact() throws {
        let data = try LaunchdService().buildPlist(
            label: "com.sysm.test",
            command: "echo '<a>' && true",
            schedule: LaunchdService.Job.Schedule(
                minute: 5, hour: 2, day: nil, weekday: nil, month: nil, interval: nil
            ),
            runAtLoad: true,
            workingDirectory: "/tmp/a&b",
            stdoutPath: "/tmp/out.log",
            stderrPath: "/tmp/err.log",
            env: ["K&EY": "v<1>"]
        )

        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        XCTAssertEqual(plist["Label"] as? String, "com.sysm.test")
        XCTAssertEqual(plist["ProgramArguments"] as? [String], ["/bin/bash", "-c", "echo '<a>' && true"])
        XCTAssertEqual(plist["WorkingDirectory"] as? String, "/tmp/a&b")
        XCTAssertEqual(plist["EnvironmentVariables"] as? [String: String], ["K&EY": "v<1>"])
        XCTAssertEqual(plist["StartCalendarInterval"] as? [String: Int], ["Minute": 5, "Hour": 2])
        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
        XCTAssertNil(plist["StartInterval"])
    }

    func testPlistUsesStartIntervalForIntervalSchedules() throws {
        let data = try LaunchdService().buildPlist(
            label: "com.sysm.tick",
            command: "true",
            schedule: LaunchdService.Job.Schedule(
                minute: nil, hour: nil, day: nil, weekday: nil, month: nil, interval: 300
            ),
            runAtLoad: false,
            workingDirectory: nil,
            stdoutPath: "/tmp/out.log",
            stderrPath: "/tmp/err.log",
            env: nil
        )

        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        XCTAssertEqual(plist["StartInterval"] as? Int, 300)
        XCTAssertNil(plist["StartCalendarInterval"])
        XCTAssertNil(plist["RunAtLoad"])
        XCTAssertNil(plist["WorkingDirectory"])
        XCTAssertNil(plist["EnvironmentVariables"])
    }

    // MARK: - Helpers

    private func assertInvalidName<T>(
        _ expression: @autoclosure () throws -> T,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), message.debugDescription, file: file, line: line) { error in
            guard case LaunchdService.LaunchdError.invalidName = error else {
                return XCTFail("\(message.debugDescription): expected invalidName, got \(error)", file: file, line: line)
            }
        }
    }
}
