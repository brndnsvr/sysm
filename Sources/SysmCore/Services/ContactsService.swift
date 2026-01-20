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
            CNContactSocialProfilesKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
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

    // MARK: - CRUD Operations

    public func createContact(
        givenName: String?,
        familyName: String?,
        organization: String?,
        jobTitle: String?,
        emails: [(label: String?, value: String)]?,
        phones: [(label: String?, value: String)]?,
        addresses: [ContactAddress]?,
        birthday: DateComponents?,
        note: String?,
        urls: [(label: String?, value: String)]?,
        socialProfiles: [ContactSocialProfile]?,
        relations: [(label: String, name: String)]?
    ) async throws -> Contact {
        try await ensureAccess()

        let contact = CNMutableContact()

        if let givenName = givenName {
            contact.givenName = givenName
        }
        if let familyName = familyName {
            contact.familyName = familyName
        }
        if let organization = organization {
            contact.organizationName = organization
        }
        if let jobTitle = jobTitle {
            contact.jobTitle = jobTitle
        }

        // Emails
        if let emails = emails {
            contact.emailAddresses = emails.map { email in
                CNLabeledValue(label: email.label ?? CNLabelHome, value: email.value as NSString)
            }
        }

        // Phone numbers
        if let phones = phones {
            contact.phoneNumbers = phones.map { phone in
                CNLabeledValue(label: phone.label ?? CNLabelPhoneNumberMain,
                              value: CNPhoneNumber(stringValue: phone.value))
            }
        }

        // Addresses
        if let addresses = addresses {
            contact.postalAddresses = addresses.map { addr in
                let postal = CNMutablePostalAddress()
                if let street = addr.street { postal.street = street }
                if let city = addr.city { postal.city = city }
                if let state = addr.state { postal.state = state }
                if let postalCode = addr.postalCode { postal.postalCode = postalCode }
                if let country = addr.country { postal.country = country }
                return CNLabeledValue(label: addr.label ?? CNLabelHome, value: postal)
            }
        }

        // Birthday
        if let birthday = birthday {
            contact.birthday = birthday
        }

        // Note
        if let note = note {
            contact.note = note
        }

        // URLs
        if let urls = urls {
            contact.urlAddresses = urls.map { url in
                CNLabeledValue(label: url.label ?? CNLabelURLAddressHomePage, value: url.value as NSString)
            }
        }

        // Social profiles
        if let profiles = socialProfiles {
            contact.socialProfiles = profiles.map { profile in
                let socialProfile = CNSocialProfile(
                    urlString: profile.url,
                    username: profile.username,
                    userIdentifier: nil,
                    service: profile.service
                )
                return CNLabeledValue(label: nil, value: socialProfile)
            }
        }

        // Relations
        if let relations = relations {
            contact.contactRelations = relations.map { relation in
                CNLabeledValue(
                    label: relation.label,
                    value: CNContactRelation(name: relation.name)
                )
            }
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            try store.execute(saveRequest)
        } catch {
            throw ContactsError.saveFailed(error.localizedDescription)
        }

        // Fetch the created contact to get its identifier
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
            CNContactSocialProfilesKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
        ]

        let fetchedContact = try store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch)
        return Contact(from: fetchedContact, detailed: true)
    }

    public func updateContact(
        identifier: String,
        givenName: String?,
        familyName: String?,
        organization: String?,
        jobTitle: String?,
        emails: [(label: String?, value: String)]?,
        phones: [(label: String?, value: String)]?,
        note: String?
    ) async throws -> Contact {
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
            CNContactSocialProfilesKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
        ]

        let contact: CNContact
        do {
            contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
        } catch {
            throw ContactsError.contactNotFound(identifier)
        }

        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            throw ContactsError.saveFailed("Unable to modify contact")
        }

        if let givenName = givenName {
            mutableContact.givenName = givenName
        }
        if let familyName = familyName {
            mutableContact.familyName = familyName
        }
        if let organization = organization {
            mutableContact.organizationName = organization
        }
        if let jobTitle = jobTitle {
            mutableContact.jobTitle = jobTitle
        }
        if let emails = emails {
            mutableContact.emailAddresses = emails.map { email in
                CNLabeledValue(label: email.label ?? CNLabelHome, value: email.value as NSString)
            }
        }
        if let phones = phones {
            mutableContact.phoneNumbers = phones.map { phone in
                CNLabeledValue(label: phone.label ?? CNLabelPhoneNumberMain,
                              value: CNPhoneNumber(stringValue: phone.value))
            }
        }
        if let note = note {
            mutableContact.note = note
        }

        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)

        do {
            try store.execute(saveRequest)
        } catch {
            throw ContactsError.saveFailed(error.localizedDescription)
        }

        let updatedContact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
        return Contact(from: updatedContact, detailed: true)
    }

    public func deleteContact(identifier: String) async throws -> Bool {
        try await ensureAccess()

        let keysToFetch: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor]

        let contact: CNContact
        do {
            contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
        } catch {
            return false
        }

        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            return false
        }

        let saveRequest = CNSaveRequest()
        saveRequest.delete(mutableContact)

        do {
            try store.execute(saveRequest)
            return true
        } catch {
            throw ContactsError.saveFailed(error.localizedDescription)
        }
    }
}

// MARK: - Models

/// Represents a postal address for a contact.
public struct ContactAddress: Codable {
    public let label: String?
    public let street: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?

    public init(label: String? = nil, street: String? = nil, city: String? = nil,
                state: String? = nil, postalCode: String? = nil, country: String? = nil) {
        self.label = label
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }

    public var formatted: String {
        [street, city, state, postalCode, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

/// Represents a social media profile for a contact.
public struct ContactSocialProfile: Codable {
    public let service: String  // "twitter", "facebook", "linkedin", etc.
    public let username: String
    public let url: String?

    public init(service: String, username: String, url: String? = nil) {
        self.service = service
        self.username = username
        self.url = url
    }
}

/// Represents a relationship to another person.
public struct ContactRelation: Codable {
    public let label: String  // "spouse", "parent", "child", "friend", etc.
    public let name: String

    public init(label: String, name: String) {
        self.label = label
        self.name = name
    }
}

public struct Contact: Codable {
    public let identifier: String
    public let givenName: String
    public let familyName: String
    public let middleName: String?
    public let organization: String?
    public let jobTitle: String?
    public let emails: [String]
    public let phones: [String]
    public let addresses: [String]?
    public let birthday: String?
    public let note: String?
    public let urls: [String]?
    public let socialProfiles: [ContactSocialProfile]?
    public let relations: [ContactRelation]?

    public var fullName: String {
        "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
    }

    public init(from contact: CNContact, detailed: Bool = false) {
        self.identifier = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.middleName = contact.middleName.isEmpty ? nil : contact.middleName
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

            // Social profiles
            if contact.socialProfiles.isEmpty {
                self.socialProfiles = nil
            } else {
                self.socialProfiles = contact.socialProfiles.map { profile in
                    ContactSocialProfile(
                        service: profile.value.service,
                        username: profile.value.username,
                        url: profile.value.urlString.isEmpty ? nil : profile.value.urlString
                    )
                }
            }

            // Relations
            if contact.contactRelations.isEmpty {
                self.relations = nil
            } else {
                self.relations = contact.contactRelations.map { relation in
                    ContactRelation(
                        label: relation.label ?? "other",
                        name: relation.value.name
                    )
                }
            }
        } else {
            self.jobTitle = nil
            self.addresses = nil
            self.birthday = nil
            self.note = nil
            self.urls = nil
            self.socialProfiles = nil
            self.relations = nil
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
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Contacts access denied. Grant permission in System Settings > Privacy & Security > Contacts"
        case .contactNotFound(let id):
            return "Contact '\(id)' not found"
        case .saveFailed(let reason):
            return "Failed to save contact: \(reason)"
        }
    }
}
