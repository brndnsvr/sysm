import Foundation
import Security

/// CalDAV service for managing calendar attendees via iCloud.
///
/// This actor communicates directly with iCloud's CalDAV server to add attendees
/// to calendar events, bypassing EventKit's read-only limitation on EKParticipant.
/// iCloud automatically sends invitation emails when new ATTENDEE properties are added.
public actor CalDAVService: CalDAVServiceProtocol {

    private static let keychainService = "com.brndnsvr.sysm.caldav"
    private static let keychainAccountAppleID = "apple-id"
    private static let keychainAccountPassword = "app-password"
    private static let baseURL = "https://caldav.icloud.com"

    // Cached discovery results (valid for the lifetime of this actor instance)
    private var cachedPrincipalURL: String?
    private var cachedCalendarHomeURL: String?
    private var cachedCalendars: [CalDAVCalendar]?

    public init() {}

    // MARK: - Credential Management

    public nonisolated func isConfigured() -> Bool {
        (try? getKeychainValue(account: Self.keychainAccountAppleID)) != nil &&
        (try? getKeychainValue(account: Self.keychainAccountPassword)) != nil
    }

    public nonisolated func setCredentials(appleID: String, appPassword: String) throws {
        try setKeychainValue(appleID, account: Self.keychainAccountAppleID)
        try setKeychainValue(appPassword, account: Self.keychainAccountPassword)
    }

    public nonisolated func removeCredentials() throws {
        try deleteKeychainItem(account: Self.keychainAccountAppleID)
        try deleteKeychainItem(account: Self.keychainAccountPassword)
    }

    // MARK: - CalDAV Discovery

    public func discoverCalendars() async throws -> [CalDAVCalendar] {
        if let cached = cachedCalendars { return cached }

        let homeURL = try await discoverCalendarHome()
        let calendars = try await enumerateCalendars(homeURL: homeURL)
        cachedCalendars = calendars
        return calendars
    }

    // MARK: - Attendee Management

    public func addAttendees(emails: [String], toEventUID uid: String, calendarName: String?, organizerEmail: String?) async throws {
        let calendars = try await discoverCalendars()

        // Find the event across calendars (or in a specific one)
        let targetCalendars: [CalDAVCalendar]
        if let name = calendarName {
            let matched = calendars.filter { $0.displayName == name }
            guard !matched.isEmpty else {
                throw CalDAVError.calendarNotFound(name)
            }
            targetCalendars = matched
        } else {
            targetCalendars = calendars
        }

        var eventResource: CalDAVEventResource?
        for calendar in targetCalendars {
            if let found = try await findEventByUID(uid: uid, calendarHref: calendar.href) {
                eventResource = found
                break
            }
        }

        guard let resource = eventResource else {
            throw CalDAVError.eventNotFound(uid)
        }

        // Get organizer email (use configured Apple ID if not specified)
        let organizer = organizerEmail ?? (try? getKeychainValue(account: Self.keychainAccountAppleID)) ?? ""

        // Modify ICS to add attendees
        let modifiedICS = addAttendeesToICS(
            icsData: resource.icsData,
            emails: emails,
            organizerEmail: organizer
        )

        // PUT the modified event back
        try await putEvent(href: resource.href, etag: resource.etag, icsData: modifiedICS)
    }

    // MARK: - Private CalDAV Operations

    private func discoverPrincipal() async throws -> String {
        if let cached = cachedPrincipalURL { return cached }

        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <D:propfind xmlns:D="DAV:">
          <D:prop>
            <D:current-user-principal/>
          </D:prop>
        </D:propfind>
        """

        let data = try await caldavRequest(
            method: "PROPFIND",
            path: "/",
            body: xmlBody,
            headers: ["Depth": "0"]
        )

        let parser = CalDAVXMLParser()
        let responses = try parser.parse(data: data)

        for response in responses {
            if let href = response.properties["href"], !href.isEmpty {
                cachedPrincipalURL = href
                return href
            }
        }

        throw CalDAVError.invalidResponse("Could not find current-user-principal")
    }

    private func discoverCalendarHome() async throws -> String {
        if let cached = cachedCalendarHomeURL { return cached }

        let principalURL = try await discoverPrincipal()

        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
          <D:prop>
            <C:calendar-home-set/>
          </D:prop>
        </D:propfind>
        """

        let data = try await caldavRequest(
            method: "PROPFIND",
            path: principalURL,
            body: xmlBody,
            headers: ["Depth": "0"]
        )

        let parser = CalDAVXMLParser()
        let responses = try parser.parse(data: data)

        for response in responses {
            if let href = response.properties["href"], !href.isEmpty {
                cachedCalendarHomeURL = href
                return href
            }
        }

        throw CalDAVError.invalidResponse("Could not find calendar-home-set")
    }

    private func enumerateCalendars(homeURL: String) async throws -> [CalDAVCalendar] {
        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav" xmlns:CS="http://calendarserver.org/ns/">
          <D:prop>
            <D:displayname/>
            <D:resourcetype/>
            <CS:getctag/>
          </D:prop>
        </D:propfind>
        """

        let data = try await caldavRequest(
            method: "PROPFIND",
            path: homeURL,
            body: xmlBody,
            headers: ["Depth": "1"]
        )

        let parser = CalDAVXMLParser()
        let responses = try parser.parse(data: data)

        var calendars: [CalDAVCalendar] = []
        for response in responses {
            // Only include actual calendar collections
            guard response.properties["resourcetype"] == "calendar" else { continue }
            guard let displayName = response.properties["displayname"], !displayName.isEmpty else { continue }

            calendars.append(CalDAVCalendar(
                href: response.href,
                displayName: displayName,
                ctag: response.properties["getctag"]
            ))
        }

        return calendars
    }

    private func findEventByUID(uid: String, calendarHref: String) async throws -> CalDAVEventResource? {
        let xmlBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
          <D:prop>
            <D:getetag/>
            <C:calendar-data/>
          </D:prop>
          <C:filter>
            <C:comp-filter name="VCALENDAR">
              <C:comp-filter name="VEVENT">
                <C:prop-filter name="UID">
                  <C:text-match collation="i;octet">\(escapeXML(uid))</C:text-match>
                </C:prop-filter>
              </C:comp-filter>
            </C:comp-filter>
          </C:filter>
        </C:calendar-query>
        """

        let data = try await caldavRequest(
            method: "REPORT",
            path: calendarHref,
            body: xmlBody,
            headers: ["Depth": "1"]
        )

        let parser = CalDAVXMLParser()
        let responses = try parser.parse(data: data)

        for response in responses {
            guard let etag = response.properties["getetag"],
                  let calendarData = response.properties["calendar-data"],
                  !calendarData.isEmpty else { continue }

            return CalDAVEventResource(
                href: response.href,
                etag: etag.trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
                icsData: calendarData
            )
        }

        return nil
    }

    private func putEvent(href: String, etag: String, icsData: String) async throws {
        let _ = try await caldavRequest(
            method: "PUT",
            path: href,
            body: icsData,
            headers: [
                "If-Match": "\"\(etag)\"",
                "Content-Type": "text/calendar; charset=utf-8",
            ],
            contentType: "text/calendar; charset=utf-8",
            acceptStatuses: [200, 201, 204]
        )
    }

    // MARK: - ICS Manipulation

    private func addAttendeesToICS(icsData: String, emails: [String], organizerEmail: String) -> String {
        var lines = icsData.components(separatedBy: "\r\n")
        if lines.count <= 1 {
            lines = icsData.components(separatedBy: "\n")
        }

        var result: [String] = []
        var addedAttendees = false

        for line in lines {
            // Insert attendees before END:VEVENT
            if line.trimmingCharacters(in: .whitespaces) == "END:VEVENT" && !addedAttendees {
                // Add ORGANIZER if not already present
                let hasOrganizer = result.contains { $0.hasPrefix("ORGANIZER") }
                if !hasOrganizer && !organizerEmail.isEmpty {
                    result.append("ORGANIZER;CN=\(organizerEmail):mailto:\(organizerEmail)")
                }

                // Check which attendees are already present
                let existingAttendees = Set(result.compactMap { line -> String? in
                    guard line.hasPrefix("ATTENDEE") else { return nil }
                    guard let mailtoRange = line.range(of: "mailto:", options: .caseInsensitive) else { return nil }
                    return String(line[mailtoRange.upperBound...]).lowercased()
                })

                // Add new attendees
                for email in emails {
                    guard !existingAttendees.contains(email.lowercased()) else { continue }
                    result.append("ATTENDEE;CN=\(email);CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:\(email)")
                }

                addedAttendees = true
            }

            // Change METHOD from PUBLISH to REQUEST if present
            if line.hasPrefix("METHOD:PUBLISH") {
                result.append("METHOD:REQUEST")
            } else {
                result.append(line)
            }
        }

        // Add METHOD:REQUEST if not present at all
        if !result.contains(where: { $0.hasPrefix("METHOD:") }) {
            if let vcalIndex = result.firstIndex(where: { $0.hasPrefix("BEGIN:VCALENDAR") }) {
                result.insert("METHOD:REQUEST", at: vcalIndex + 1)
            }
        }

        return result.joined(separator: "\r\n")
    }

    // MARK: - HTTP

    private func caldavRequest(
        method: String,
        path: String,
        body: String,
        headers: [String: String] = [:],
        contentType: String? = nil,
        acceptStatuses: [Int] = [200, 207]
    ) async throws -> Data {
        let credentials = try requireCredentials()
        let credentialString = "\(credentials.appleID):\(credentials.appPassword)"
        guard let credentialData = credentialString.data(using: .utf8) else {
            throw CalDAVError.authenticationFailed
        }
        let base64Credentials = credentialData.base64EncodedString()

        let urlString: String
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            urlString = path
        } else {
            urlString = Self.baseURL + path
        }

        guard let url = URL(string: urlString) else {
            throw CalDAVError.invalidResponse("Invalid URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType ?? "application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)

        for (key, value) in headers {
            if key != "Content-Type" {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CalDAVError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalDAVError.networkError("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw CalDAVError.authenticationFailed
        }

        guard acceptStatuses.contains(httpResponse.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw CalDAVError.serverError(httpResponse.statusCode, bodyString)
        }

        return data
    }

    // MARK: - Keychain

    private struct Credentials {
        let appleID: String
        let appPassword: String
    }

    private nonisolated func requireCredentials() throws -> Credentials {
        let appleID = try getKeychainValue(account: Self.keychainAccountAppleID)
        let appPassword = try getKeychainValue(account: Self.keychainAccountPassword)
        return Credentials(appleID: appleID, appPassword: appPassword)
    }

    private nonisolated func getKeychainValue(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw CalDAVError.notConfigured
        }
        return value
    }

    private nonisolated func setKeychainValue(_ value: String, account: String) throws {
        try? deleteKeychainItem(account: account)

        let valueData = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: valueData,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CalDAVError.networkError("Failed to save to Keychain (status: \(status))")
        }
    }

    private nonisolated func deleteKeychainItem(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw CalDAVError.networkError("Failed to delete Keychain item (status: \(status))")
        }
    }

    // MARK: - Helpers

    private func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
