import Darwin
import Foundation
import XCTest

@testable import SysmCore

final class SecretInputTests: XCTestCase {
    func testStandardInputReadsExactValueAndTrimsOneLineEnding() throws {
        let pipe = try makePipe(containing: Data("secret-value\r\n".utf8))
        defer { close(pipe.read) }

        let reader = SecretInputReader(standardInputDescriptor: pipe.read)
        let value = try reader.read(
            from: .standardInput,
            prompt: "Ignored: ",
            maximumBytes: 64
        )

        XCTAssertEqual(value, "secret-value")
    }

    func testInheritedDescriptorReadsExactValue() throws {
        let pipe = try makePipe(containing: Data("fd-secret\n".utf8))
        defer { close(pipe.read) }

        let reader = SecretInputReader()
        let value = try reader.read(
            from: .fileDescriptor(pipe.read),
            prompt: "Ignored: ",
            maximumBytes: 64
        )

        XCTAssertEqual(value, "fd-secret")
    }

    func testStandardInputRejectsEmptyValue() throws {
        let pipe = try makePipe(containing: Data())
        defer { close(pipe.read) }

        let reader = SecretInputReader(standardInputDescriptor: pipe.read)

        XCTAssertThrowsError(
            try reader.read(from: .standardInput, prompt: "Ignored: ", maximumBytes: 64)
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .emptyInput)
        }
    }

    func testStandardInputRejectsNUL() throws {
        let pipe = try makePipe(containing: Data([0x73, 0x65, 0x00, 0x63, 0x72, 0x65, 0x74]))
        defer { close(pipe.read) }

        let reader = SecretInputReader(standardInputDescriptor: pipe.read)

        XCTAssertThrowsError(
            try reader.read(from: .standardInput, prompt: "Ignored: ", maximumBytes: 64)
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .containsNUL)
        }
    }

    func testStandardInputRejectsInvalidUTF8() throws {
        let pipe = try makePipe(containing: Data([0xC3, 0x28]))
        defer { close(pipe.read) }

        let reader = SecretInputReader(standardInputDescriptor: pipe.read)

        XCTAssertThrowsError(
            try reader.read(from: .standardInput, prompt: "Ignored: ", maximumBytes: 64)
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .invalidUTF8)
        }
    }

    func testStandardInputRejectsOversizedValueWithoutTruncating() throws {
        let pipe = try makePipe(containing: Data("12345".utf8))
        defer { close(pipe.read) }

        let reader = SecretInputReader(standardInputDescriptor: pipe.read)

        XCTAssertThrowsError(
            try reader.read(from: .standardInput, prompt: "Ignored: ", maximumBytes: 4)
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .inputTooLong(maximumBytes: 4))
        }
    }

    func testFileDescriptorMustNotUseStandardStreams() {
        let reader = SecretInputReader()

        XCTAssertThrowsError(
            try reader.read(from: .fileDescriptor(STDERR_FILENO), prompt: "Ignored: ")
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .invalidFileDescriptor(STDERR_FILENO))
        }
    }

    func testClosedFileDescriptorFailsWithoutLeakingInput() throws {
        let sentinel = "DO_NOT_LEAK_7Q9"
        let pipe = try makePipe(containing: Data(sentinel.utf8))
        close(pipe.read)

        let reader = SecretInputReader()

        XCTAssertThrowsError(
            try reader.read(from: .fileDescriptor(pipe.read), prompt: "Ignored: ")
        ) { error in
            guard case .readFailed = error as? SecretInputError else {
                XCTFail("Expected a redacted read failure, got \(error)")
                return
            }
            XCTAssertFalse(error.localizedDescription.contains(sentinel))
        }
    }

    func testInvalidMaximumLengthIsRejected() {
        let reader = SecretInputReader()

        XCTAssertThrowsError(
            try reader.read(from: .standardInput, prompt: "Ignored: ", maximumBytes: 0)
        ) { error in
            XCTAssertEqual(error as? SecretInputError, .invalidMaximumBytes)
        }
    }

    private func makePipe(containing data: Data) throws -> (read: Int32, write: Int32) {
        var descriptors: [Int32] = [0, 0]
        guard Darwin.pipe(&descriptors) == 0 else {
            throw POSIXError(.EIO)
        }

        let readDescriptor = descriptors[0]
        let writeDescriptor = descriptors[1]

        do {
            try data.withUnsafeBytes { buffer in
                var written = 0
                while written < buffer.count {
                    let result = Darwin.write(
                        writeDescriptor,
                        buffer.baseAddress!.advanced(by: written),
                        buffer.count - written
                    )
                    if result < 0 {
                        if errno == EINTR { continue }
                        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
                    }
                    written += result
                }
            }
            close(writeDescriptor)
            return (readDescriptor, writeDescriptor)
        } catch {
            close(readDescriptor)
            close(writeDescriptor)
            throw error
        }
    }
}
