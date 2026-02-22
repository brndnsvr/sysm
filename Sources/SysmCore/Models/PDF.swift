import Foundation

public struct PDFInfo: Codable, Sendable {
    public let path: String
    public let pageCount: Int
    public let versionMajor: Int
    public let versionMinor: Int
    public let fileSize: Int64
    public let fileSizeFormatted: String
    public let isEncrypted: Bool
    public let isLocked: Bool
    public let title: String?
    public let author: String?
    public let subject: String?
    public let creator: String?
    public let producer: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let keywords: [String]?

    public init(path: String, pageCount: Int, versionMajor: Int, versionMinor: Int,
                fileSize: Int64, fileSizeFormatted: String, isEncrypted: Bool, isLocked: Bool,
                title: String?, author: String?, subject: String?, creator: String?,
                producer: String?, creationDate: Date?, modificationDate: Date?,
                keywords: [String]?) {
        self.path = path
        self.pageCount = pageCount
        self.versionMajor = versionMajor
        self.versionMinor = versionMinor
        self.fileSize = fileSize
        self.fileSizeFormatted = fileSizeFormatted
        self.isEncrypted = isEncrypted
        self.isLocked = isLocked
        self.title = title
        self.author = author
        self.subject = subject
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.keywords = keywords
    }
}

public struct PDFPageInfo: Codable, Sendable {
    public let index: Int
    public let label: String?
    public let width: Double
    public let height: Double
    public let rotation: Int
    public let characterCount: Int
    public let annotationCount: Int

    public init(index: Int, label: String?, width: Double, height: Double,
                rotation: Int, characterCount: Int, annotationCount: Int) {
        self.index = index
        self.label = label
        self.width = width
        self.height = height
        self.rotation = rotation
        self.characterCount = characterCount
        self.annotationCount = annotationCount
    }
}

public struct PDFSearchResult: Codable, Sendable {
    public let page: Int
    public let pageLabel: String?
    public let contextSnippet: String

    public init(page: Int, pageLabel: String?, contextSnippet: String) {
        self.page = page
        self.pageLabel = pageLabel
        self.contextSnippet = contextSnippet
    }
}

public struct PDFAnnotationInfo: Codable, Sendable {
    public let page: Int
    public let type: String
    public let boundsX: Double
    public let boundsY: Double
    public let boundsWidth: Double
    public let boundsHeight: Double
    public let contents: String?
    public let author: String?
    public let color: String?
    public let modificationDate: Date?

    public init(page: Int, type: String, boundsX: Double, boundsY: Double,
                boundsWidth: Double, boundsHeight: Double, contents: String?,
                author: String?, color: String?, modificationDate: Date?) {
        self.page = page
        self.type = type
        self.boundsX = boundsX
        self.boundsY = boundsY
        self.boundsWidth = boundsWidth
        self.boundsHeight = boundsHeight
        self.contents = contents
        self.author = author
        self.color = color
        self.modificationDate = modificationDate
    }
}

public struct PDFOutlineEntry: Codable, Sendable {
    public let title: String
    public let pageIndex: Int?
    public let pageLabel: String?
    public let depth: Int
    public let children: [PDFOutlineEntry]

    public init(title: String, pageIndex: Int?, pageLabel: String?, depth: Int,
                children: [PDFOutlineEntry]) {
        self.title = title
        self.pageIndex = pageIndex
        self.pageLabel = pageLabel
        self.depth = depth
        self.children = children
    }
}

public struct PDFPermissions: Codable, Sendable {
    public let printing: Bool
    public let copying: Bool
    public let contentAccessibility: Bool
    public let commenting: Bool

    public init(printing: Bool, copying: Bool, contentAccessibility: Bool, commenting: Bool) {
        self.printing = printing
        self.copying = copying
        self.contentAccessibility = contentAccessibility
        self.commenting = commenting
    }
}
