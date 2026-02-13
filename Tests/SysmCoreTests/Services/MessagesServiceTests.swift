//
//  MessagesServiceTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class MessagesServiceTests: XCTestCase {
    var mockRunner: MockAppleScriptRunner!
    var service: MessagesService!

    override func setUp() {
        super.setUp()
        mockRunner = MockAppleScriptRunner()
        service = MessagesService(scriptRunner: mockRunner)
    }

    override func tearDown() {
        mockRunner = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Send Message Tests

    func testSendMessage() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "+1234567890",
                message: "Test message"
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("+1234567890"))
        XCTAssertTrue(script.contains("Test message"))
        XCTAssertTrue(script.contains("send"))
    }

    func testSendMessageWithEscaping() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "test@icloud.com",
                message: "Message with 'quotes' and \"double quotes\""
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("\\"))
    }

    func testSendMessageMultiline() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "+1234567890",
                message: "Line 1\nLine 2\nLine 3"
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("Line 1"))
    }

    // MARK: - Error Tests

    func testMessagesNotRunning() {
        mockRunner.mockErrors["messages-send"] = MessagesError.messagesNotRunning

        XCTAssertThrowsError(
            try service.sendMessage(to: "+1234567890", message: "Test")
        ) { error in
            XCTAssertTrue(error is MessagesError)
            if case MessagesError.messagesNotRunning = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testSendFailed() {
        mockRunner.mockErrors["messages-send"] = MessagesError.sendFailed("Network error")

        XCTAssertThrowsError(
            try service.sendMessage(to: "+1234567890", message: "Test")
        ) { error in
            XCTAssertTrue(error is MessagesError)
        }
    }

    // MARK: - Input Validation Tests

    func testSendToEmail() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "user@icloud.com",
                message: "iMessage test"
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("user@icloud.com"))
    }

    func testSendToPhoneNumber() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "+1 (555) 123-4567",
                message: "SMS test"
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("(555)") || script.contains("555"))
    }

    // MARK: - Script Generation Tests

    func testScriptGenerationForSend() throws {
        mockRunner.mockResponses["messages-send"] = "success"

        _ = try service.sendMessage(to: "test", message: "msg")

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("tell application \"Messages\""))
        XCTAssertTrue(script.contains("send"))
    }
}
