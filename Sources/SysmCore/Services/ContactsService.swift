import Contacts
import Foundation

public actor ContactsService: ContactsServiceProtocol {
    private let store = CNContactStore()

    // MARK: - Access

    public func ensureAccess() async throws {
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = try await store.requestAccess(for: .contacts)
            if !granted {
                throw ContactsError.accessDenied
            }
        case .denied, .restricted:
            throw ContactsError.accessDenied
        @unknown default:
            throw ContactsError.accessDenied
        }
    }

    // MARK: - Search

    public func search(query: String) async throws -> [Contact] {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]

        let predicate = CNContact.predicateForContacts(matchingName: query)

        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        return contacts.map { Contact(from: $0) }
    }

    // MARK: - Get Contact

    public func getContact(identifier: String) async throws -> Contact? {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
        ]

        do {
            let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
            return Contact(from: contact, detailed: true)
        } catch {
            return nil
        }
    }

    // MARK: - Email Search

    public func searchByEmail(query: String) async throws -> [(name: String, email: String)] {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]

        var results: [(name: String, email: String)] = []

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        try store.enumerateContacts(with: request) { contact, _ in
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

            for email in contact.emailAddresses {
                let emailStr = email.value as String
                if emailStr.lowercased().contains(query.lowercased()) ||
                   name.lowercased().contains(query.lowercased()) {
                    results.append((name: name, email: emailStr))
                }
            }
        }

        return results
    }

    // MARK: - Phone Search

    public func searchByPhone(query: String) async throws -> [(name: String, phone: String)] {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]

        var results: [(name: String, phone: String)] = []

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        try store.enumerateContacts(with: request) { contact, _ in
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

            for phone in contact.phoneNumbers {
                let phoneStr = phone.value.stringValue
                let normalized = phoneStr.filter { $0.isNumber }
                let queryNormalized = query.filter { $0.isNumber }

                if normalized.contains(queryNormalized) ||
                   name.lowercased().contains(query.lowercased()) {
                    results.append((name: name, phone: phoneStr))
                }
            }
        }

        return results
    }

    // MARK: - Birthdays

    public func getUpcomingBirthdays(days: Int = 30) async throws -> [(name: String, birthday: DateComponents, daysUntil: Int)] {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
        ]

        var birthdays: [(name: String, birthday: DateComponents, daysUntil: Int)] = []
        let today = Foundation.Calendar.current.startOfDay(for: Date())

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        try store.enumerateContacts(with: request) { contact, _ in
            guard let birthday = contact.birthday,
                  let month = birthday.month,
                  let day = birthday.day else { return }

            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

            // Calculate next birthday
            var nextBirthday = DateComponents()
            nextBirthday.month = month
            nextBirthday.day = day
            nextBirthday.year = Foundation.Calendar.current.component(.year, from: today)

            guard var nextDate = Foundation.Calendar.current.date(from: nextBirthday) else { return }

            // If birthday has passed this year, use next year
            if nextDate < today {
                nextBirthday.year = (nextBirthday.year ?? 0) + 1
                guard let next = Foundation.Calendar.current.date(from: nextBirthday) else { return }
                nextDate = next
            }

            let daysUntil = Foundation.Calendar.current.dateComponents([.day], from: today, to: nextDate).day ?? 0

            if daysUntil <= days {
                birthdays.append((name: name, birthday: birthday, daysUntil: daysUntil))
            }
        }

        return birthdays.sorted { $0.daysUntil < $1.daysUntil }
    }

    // MARK: - Groups

    public func getGroups() async throws -> [ContactGroup] {
        try await ensureAccess()

        let groups = try store.groups(matching: nil)
        return groups.map { ContactGroup(identifier: $0.identifier, name: $0.name) }
    }
}

// MARK: - Models

public struct Contact: Codable {
    public let identifier: String
    public let givenName: String
    public let familyName: String
    public let organization: String?
    public let jobTitle: String?
    public let emails: [String]
    public let phones: [String]
    public let addresses: [String]?
    public let birthday: String?
    public let note: String?
    public let urls: [String]?

    public var fullName: String {
        "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
    }

    public init(from contact: CNContact, detailed: Bool = false) {
        self.identifier = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.organization = contact.organizationName.isEmpty ? nil : contact.organizationName
        self.emails = contact.emailAddresses.map { $0.value as String }
        self.phones = contact.phoneNumbers.map { $0.value.stringValue }

        if detailed {
            self.jobTitle = contact.jobTitle.isEmpty ? nil : contact.jobTitle
            self.addresses = contact.postalAddresses.map { address -> String in
                let postal = address.value
                return [postal.street, postal.city, postal.state, postal.postalCode, postal.country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
            }

            if let bday = contact.birthday, let month = bday.month, let day = bday.day {
                if let year = bday.year {
                    self.birthday = String(format: "%04d-%02d-%02d", year, month, day)
                } else {
                    self.birthday = String(format: "%02d-%02d", month, day)
                }
            } else {
                self.birthday = nil
            }

            self.note = contact.note.isEmpty ? nil : contact.note
            self.urls = contact.urlAddresses.isEmpty ? nil : contact.urlAddresses.map { $0.value as String }
        } else {
            self.jobTitle = nil
            self.addresses = nil
            self.birthday = nil
            self.note = nil
            self.urls = nil
        }
    }
}

public struct ContactGroup: Codable {
    public let identifier: String
    public let name: String
}

// MARK: - Errors

public enum ContactsError: LocalizedError {
    case accessDenied
    case contactNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Contacts access denied. Grant permission in System Settings > Privacy & Security > Contacts"
        case .contactNotFound(let id):
            return "Contact '\(id)' not found"
        }
    }
}
