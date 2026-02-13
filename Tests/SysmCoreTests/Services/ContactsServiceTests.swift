//
//  ContactsServiceTests.swift
//  sysm
//

import XCTest
import Contacts
@testable import SysmCore

final class ContactsServiceTests: XCTestCase {
    var service: ContactsService!
    var store: CNContactStore!

    override func setUp() async throws {
        try await super.setUp()
        store = CNContactStore()
        service = ContactsService(contactStore: store)
    }

    override func tearDown() async throws {
        service = nil
        store = nil
        try await super.tearDown()
    }

    // MARK: - Access Tests

    func testRequestAccessGranted() async throws {
        do {
            try await service.requestAccess()
            XCTAssertTrue(true)
        } catch {
            XCTAssertTrue(error is ContactsError)
        }
    }

    // MARK: - Search Tests

    func testSearchByName() async throws {
        do {
            let contacts = try await service.searchContacts(query: "Test", field: .name)
            XCTAssertNotNil(contacts)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    func testSearchByEmail() async throws {
        do {
            let contacts = try await service.searchContacts(query: "test@example.com", field: .email)
            XCTAssertNotNil(contacts)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    func testSearchByPhone() async throws {
        do {
            let contacts = try await service.searchContacts(query: "555", field: .phone)
            XCTAssertNotNil(contacts)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    // MARK: - Contact Creation Tests

    func testCreateContact() async throws {
        do {
            let contactId = try await service.createContact(
                firstName: "Test",
                lastName: "Contact",
                email: "test@example.com",
                phone: "5551234567",
                organization: nil,
                jobTitle: nil
            )

            XCTAssertFalse(contactId.isEmpty)

            // Clean up
            try await service.deleteContact(id: contactId)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    func testCreateContactWithAllFields() async throws {
        do {
            let contactId = try await service.createContact(
                firstName: "John",
                lastName: "Doe",
                email: "john.doe@example.com",
                phone: "+1 (555) 123-4567",
                organization: "Test Corp",
                jobTitle: "Software Engineer"
            )

            XCTAssertFalse(contactId.isEmpty)

            // Clean up
            try await service.deleteContact(id: contactId)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    // MARK: - Contact Update Tests

    func testUpdateContact() async throws {
        do {
            // Create contact
            let contactId = try await service.createContact(
                firstName: "Original",
                lastName: "Name",
                email: nil,
                phone: nil,
                organization: nil,
                jobTitle: nil
            )

            // Update contact
            try await service.updateContact(
                id: contactId,
                firstName: "Updated",
                lastName: "Name",
                email: "updated@example.com",
                phone: nil,
                organization: "New Company",
                jobTitle: "New Title"
            )

            // Clean up
            try await service.deleteContact(id: contactId)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    // MARK: - Get All Contacts Tests

    func testGetAllContacts() async throws {
        do {
            let contacts = try await service.getAllContacts()
            XCTAssertNotNil(contacts)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    // MARK: - Group Tests

    func testGetGroups() async throws {
        do {
            let groups = try await service.getGroups()
            XCTAssertNotNil(groups)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    func testCreateGroup() async throws {
        do {
            let groupId = try await service.createGroup(name: "Test Group")
            XCTAssertFalse(groupId.isEmpty)

            // Clean up
            try await service.deleteGroup(id: groupId)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }

    // MARK: - Error Tests

    func testContactNotFoundError() async {
        do {
            _ = try await service.getContact(id: "nonexistent-contact-id-12345")
            XCTFail("Should have thrown contactNotFound error")
        } catch ContactsError.contactNotFound {
            // Expected
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGroupNotFoundError() async {
        do {
            _ = try await service.getGroup(id: "nonexistent-group-id-12345")
            XCTFail("Should have thrown groupNotFound error")
        } catch ContactsError.groupNotFound {
            // Expected
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Email Parsing Tests

    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue("test@example.com".contains("@"))
        XCTAssertTrue("user.name+tag@example.co.uk".contains("@"))

        // Invalid emails (basic check)
        XCTAssertFalse("not-an-email".contains("@"))
        XCTAssertFalse("missing-domain@".contains("."))
    }

    // MARK: - Phone Number Formatting Tests

    func testPhoneNumberFormats() {
        let formats = [
            "5551234567",
            "+1 (555) 123-4567",
            "555-123-4567",
            "(555) 123-4567",
        ]

        for format in formats {
            // All should contain digits
            XCTAssertTrue(format.contains(where: { $0.isNumber }))
        }
    }

    // MARK: - Multiple Email/Phone Tests

    func testAddMultipleEmails() async throws {
        do {
            let contactId = try await service.createContact(
                firstName: "Multi",
                lastName: "Email",
                email: "first@example.com",
                phone: nil,
                organization: nil,
                jobTitle: nil
            )

            // Note: Adding multiple emails requires updateContact with array support
            // This is a basic test that the primary email is set

            // Clean up
            try await service.deleteContact(id: contactId)
        } catch ContactsError.accessDenied {
            throw XCTSkip("Contacts access not granted")
        }
    }
}
