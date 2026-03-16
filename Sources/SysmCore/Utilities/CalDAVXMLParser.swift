import Foundation

/// Parses CalDAV XML responses (PROPFIND, REPORT).
///
/// Handles DAV: and CalDAV namespace elements to extract
/// hrefs, property values, and calendar data from multistatus responses.
public final class CalDAVXMLParser: NSObject, XMLParserDelegate {

    /// A single response element from a DAV:multistatus.
    public struct Response {
        public var href: String = ""
        public var properties: [String: String] = [:]
        public var status: String?
    }

    private var responses: [Response] = []
    private var currentResponse: Response?
    private var currentElement: String = ""
    private var currentText: String = ""
    private var inPropStat = false
    private var propStatStatus: String?
    private var propStatProperties: [String: String] = [:]
    private var parseError: Error?

    // Track resource types for filtering calendars
    private var inResourceType = false
    private var hasCalendarResourceType = false

    /// Parses a CalDAV XML response and returns an array of Response objects.
    public func parse(data: Data) throws -> [Response] {
        responses = []
        currentResponse = nil
        parseError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.parse()

        if let error = parseError {
            throw CalDAVError.xmlParseError(error.localizedDescription)
        }
        if let parserError = parser.parserError {
            throw CalDAVError.xmlParseError(parserError.localizedDescription)
        }

        return responses
    }

    // MARK: - XMLParserDelegate

    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "response":
            currentResponse = Response()
            hasCalendarResourceType = false
        case "propstat":
            inPropStat = true
            propStatStatus = nil
            propStatProperties = [:]
        case "resourcetype":
            inResourceType = true
        case "calendar" where inResourceType:
            hasCalendarResourceType = true
        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "response":
            if var response = currentResponse {
                if hasCalendarResourceType {
                    response.properties["resourcetype"] = "calendar"
                }
                responses.append(response)
            }
            currentResponse = nil

        case "href" where !inPropStat:
            if currentResponse != nil && text.count > 0 {
                currentResponse?.href = text
            }

        case "href" where inPropStat:
            // href inside propstat (e.g., calendar-home-set)
            propStatProperties["href"] = text

        case "propstat":
            // Only include properties from successful propstats
            if let status = propStatStatus, status.contains("200") {
                for (key, value) in propStatProperties {
                    currentResponse?.properties[key] = value
                }
            }
            inPropStat = false

        case "status":
            if inPropStat {
                propStatStatus = text
            } else {
                currentResponse?.status = text
            }

        case "resourcetype":
            inResourceType = false

        case "displayname":
            if inPropStat {
                propStatProperties["displayname"] = text
            }

        case "getctag":
            if inPropStat {
                propStatProperties["getctag"] = text
            }

        case "getetag":
            if inPropStat {
                propStatProperties["getetag"] = text
            }

        case "calendar-data":
            if inPropStat {
                propStatProperties["calendar-data"] = currentText
            }

        case "current-user-principal":
            // The href was already captured via the href case above
            break

        case "calendar-home-set":
            // The href was already captured via the href case above
            break

        default:
            // For nested href elements (inside current-user-principal, calendar-home-set)
            if elementName == "href" {
                if inPropStat {
                    propStatProperties["href"] = text
                }
            }
        }

        currentText = ""
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        parseError = error
    }
}
