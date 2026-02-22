import AppKit
import Foundation
import PDFKit

public struct PDFService: PDFServiceProtocol {
    public init() {}

    public func info(path: String) throws -> PDFInfo {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)
        return try buildInfo(doc: doc, path: expanded)
    }

    public func text(path: String, page: Int?) throws -> String {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        if let page = page {
            let idx = page - 1
            guard idx >= 0, idx < doc.pageCount, let pdfPage = doc.page(at: idx) else {
                throw PDFError.pageOutOfRange(page, doc.pageCount)
            }
            guard let text = pdfPage.string, !text.isEmpty else {
                throw PDFError.noTextFound
            }
            return text
        }

        guard let text = doc.string, !text.isEmpty else {
            throw PDFError.noTextFound
        }
        return text
    }

    public func search(path: String, query: String, caseSensitive: Bool) throws -> [PDFSearchResult] {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        var results: [PDFSearchResult] = []
        let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        let selections = doc.findString(query, withOptions: options)

        for selection in selections {
            guard let selPage = selection.pages.first else { continue }
            let pageIndex = doc.index(for: selPage)
            let snippet = selection.string ?? query
            results.append(PDFSearchResult(
                page: pageIndex + 1,
                pageLabel: selPage.label,
                contextSnippet: snippet
            ))
        }

        return results
    }

    public func pages(path: String) throws -> [PDFPageInfo] {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        var result: [PDFPageInfo] = []
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            result.append(PDFPageInfo(
                index: i + 1,
                label: page.label,
                width: Double(bounds.width),
                height: Double(bounds.height),
                rotation: page.rotation,
                characterCount: page.string?.count ?? 0,
                annotationCount: page.annotations.count
            ))
        }
        return result
    }

    public func thumbnail(path: String, page: Int, outputPath: String, size: Int) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        let idx = page - 1
        guard idx >= 0, idx < doc.pageCount, let pdfPage = doc.page(at: idx) else {
            throw PDFError.pageOutOfRange(page, doc.pageCount)
        }

        let bounds = pdfPage.bounds(for: .mediaBox)
        let scale = CGFloat(size) / max(bounds.width, bounds.height)
        let thumbWidth = bounds.width * scale
        let thumbHeight = bounds.height * scale
        let thumbSize = CGSize(width: thumbWidth, height: thumbHeight)

        let image = pdfPage.thumbnail(of: thumbSize, for: .mediaBox)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw PDFError.writeFailed(expandedOutput)
        }

        try ensureDirectory(for: expandedOutput)
        try pngData.write(to: URL(fileURLWithPath: expandedOutput))
    }

    public func merge(paths: [String], outputPath: String) throws {
        let expandedOutput = expandPath(outputPath)
        let newDoc = PDFDocument()

        for filePath in paths {
            let expanded = expandPath(filePath)
            let doc = try openDocument(at: expanded)
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                newDoc.insert(page, at: newDoc.pageCount)
            }
        }

        try ensureDirectory(for: expandedOutput)
        guard newDoc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func split(path: String, pageRange: ClosedRange<Int>, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        let lower = pageRange.lowerBound - 1
        let upper = pageRange.upperBound - 1

        guard lower >= 0, upper < doc.pageCount, lower <= upper else {
            throw PDFError.invalidPageRange(pageRange.lowerBound, pageRange.upperBound, doc.pageCount)
        }

        let newDoc = PDFDocument()
        for i in lower...upper {
            guard let page = doc.page(at: i) else { continue }
            newDoc.insert(page, at: newDoc.pageCount)
        }

        try ensureDirectory(for: expandedOutput)
        guard newDoc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func rotate(path: String, pages: [Int], angle: Int, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)

        guard [0, 90, 180, 270].contains(angle) else {
            throw PDFError.invalidRotation(angle)
        }

        let doc = try openDocument(at: expanded)

        for pageNum in pages {
            let idx = pageNum - 1
            guard idx >= 0, idx < doc.pageCount, let page = doc.page(at: idx) else {
                throw PDFError.pageOutOfRange(pageNum, doc.pageCount)
            }
            page.rotation = (page.rotation + angle) % 360
        }

        try ensureDirectory(for: expandedOutput)
        guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func encrypt(path: String, ownerPassword: String, userPassword: String?,
                        outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        try ensureDirectory(for: expandedOutput)

        let options: [PDFDocumentWriteOption: Any] = [
            .ownerPasswordOption: ownerPassword,
            .userPasswordOption: userPassword ?? "",
        ]

        guard doc.write(to: URL(fileURLWithPath: expandedOutput), withOptions: options) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func decrypt(path: String, password: String, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)

        guard let doc = PDFDocument(url: URL(fileURLWithPath: expanded)) else {
            throw PDFError.invalidDocument(expanded)
        }

        if doc.isLocked {
            guard doc.unlock(withPassword: password) else {
                throw PDFError.documentLocked(expanded)
            }
        }

        try ensureDirectory(for: expandedOutput)
        guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func metadata(path: String) throws -> PDFInfo {
        return try info(path: path)
    }

    public func setMetadata(path: String, title: String?, author: String?, subject: String?,
                            keywords: [String]?, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        var attrs = doc.documentAttributes ?? [:]

        if let title = title { attrs[PDFDocumentAttribute.titleAttribute] = title }
        if let author = author { attrs[PDFDocumentAttribute.authorAttribute] = author }
        if let subject = subject { attrs[PDFDocumentAttribute.subjectAttribute] = subject }
        if let keywords = keywords { attrs[PDFDocumentAttribute.keywordsAttribute] = keywords }

        doc.documentAttributes = attrs

        try ensureDirectory(for: expandedOutput)
        guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func annotations(path: String, page: Int?) throws -> [PDFAnnotationInfo] {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        var results: [PDFAnnotationInfo] = []

        let startPage = page.map { $0 - 1 } ?? 0
        let endPage = page.map { $0 - 1 } ?? (doc.pageCount - 1)

        if let page = page {
            guard startPage >= 0, startPage < doc.pageCount else {
                throw PDFError.pageOutOfRange(page, doc.pageCount)
            }
        }

        for i in startPage...endPage {
            guard let pdfPage = doc.page(at: i) else { continue }
            for annotation in pdfPage.annotations {
                let bounds = annotation.bounds
                let colorStr = annotation.color.description
                results.append(PDFAnnotationInfo(
                    page: i + 1,
                    type: annotation.type ?? "unknown",
                    boundsX: Double(bounds.origin.x),
                    boundsY: Double(bounds.origin.y),
                    boundsWidth: Double(bounds.size.width),
                    boundsHeight: Double(bounds.size.height),
                    contents: annotation.contents,
                    author: annotation.userName,
                    color: colorStr,
                    modificationDate: annotation.modificationDate
                ))
            }
        }

        return results
    }

    public func addAnnotation(path: String, page: Int, type: String, text: String,
                              x: Double, y: Double, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        let idx = page - 1
        guard idx >= 0, idx < doc.pageCount, let pdfPage = doc.page(at: idx) else {
            throw PDFError.pageOutOfRange(page, doc.pageCount)
        }

        let bounds = CGRect(x: x, y: y, width: 200, height: 100)
        let annotation: PDFAnnotation

        switch type.lowercased() {
        case "note":
            annotation = PDFAnnotation(bounds: CGRect(x: x, y: y, width: 24, height: 24),
                                       forType: .text, withProperties: nil)
            annotation.contents = text
            annotation.color = .yellow
        case "text", "freetext":
            annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = NSFont.systemFont(ofSize: 12)
            annotation.color = .clear
            annotation.fontColor = .black
        default:
            annotation = PDFAnnotation(bounds: CGRect(x: x, y: y, width: 24, height: 24),
                                       forType: .text, withProperties: nil)
            annotation.contents = text
            annotation.color = .yellow
        }

        pdfPage.addAnnotation(annotation)

        try ensureDirectory(for: expandedOutput)
        guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func watermark(path: String, text: String, fontSize: Double, opacity: Double,
                          angle: Double, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)

            let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = NSFont.systemFont(ofSize: CGFloat(fontSize))
            annotation.fontColor = NSColor.gray.withAlphaComponent(CGFloat(opacity))
            annotation.color = .clear
            annotation.alignment = .center

            page.addAnnotation(annotation)
        }

        try ensureDirectory(for: expandedOutput)

        let options: [PDFDocumentWriteOption: Any] = [
            .burnInAnnotationsOption: true,
        ]
        guard doc.write(to: URL(fileURLWithPath: expandedOutput), withOptions: options) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func compress(path: String, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        try ensureDirectory(for: expandedOutput)

        if #available(macOS 13.4, *) {
            let options: [PDFDocumentWriteOption: Any] = [
                .saveImagesAsJPEGOption: true,
                .optimizeImagesForScreenOption: true,
            ]
            guard doc.write(to: URL(fileURLWithPath: expandedOutput), withOptions: options) else {
                throw PDFError.writeFailed(expandedOutput)
            }
        } else {
            guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
                throw PDFError.writeFailed(expandedOutput)
            }
        }
    }

    public func ocrEmbed(path: String, outputPath: String) throws {
        let expanded = expandPath(path)
        let expandedOutput = expandPath(outputPath)
        let doc = try openDocument(at: expanded)

        try ensureDirectory(for: expandedOutput)

        if #available(macOS 13.4, *) {
            let options: [PDFDocumentWriteOption: Any] = [
                .saveTextFromOCROption: true,
            ]
            guard doc.write(to: URL(fileURLWithPath: expandedOutput), withOptions: options) else {
                throw PDFError.writeFailed(expandedOutput)
            }
        } else {
            guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
                throw PDFError.writeFailed(expandedOutput)
            }
        }
    }

    public func imagesToPDF(imagePaths: [String], outputPath: String) throws {
        let expandedOutput = expandPath(outputPath)
        let doc = PDFDocument()

        for imagePath in imagePaths {
            let expanded = expandPath(imagePath)
            guard let image = NSImage(contentsOfFile: expanded) else {
                throw PDFError.invalidDocument(expanded)
            }
            guard let page = PDFPage(image: image) else {
                throw PDFError.writeFailed("Failed to create PDF page from: \(expanded)")
            }
            doc.insert(page, at: doc.pageCount)
        }

        try ensureDirectory(for: expandedOutput)
        guard doc.write(to: URL(fileURLWithPath: expandedOutput)) else {
            throw PDFError.writeFailed(expandedOutput)
        }
    }

    public func outline(path: String) throws -> [PDFOutlineEntry] {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        guard let root = doc.outlineRoot else {
            return []
        }

        return buildOutlineEntries(from: root, doc: doc, depth: 0)
    }

    public func permissions(path: String) throws -> PDFPermissions {
        let expanded = expandPath(path)
        let doc = try openDocument(at: expanded)

        return PDFPermissions(
            printing: doc.allowsPrinting,
            copying: doc.allowsCopying,
            contentAccessibility: doc.allowsContentAccessibility,
            commenting: doc.allowsCommenting
        )
    }

    // MARK: - Private

    private func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func ensureDirectory(for filePath: String) throws {
        let dir = (filePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    }

    private func openDocument(at path: String) throws -> PDFDocument {
        guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            throw PDFError.invalidDocument(path)
        }
        if doc.isLocked {
            throw PDFError.documentLocked(path)
        }
        return doc
    }

    private func buildInfo(doc: PDFDocument, path: String) throws -> PDFInfo {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let fileSize = (attrs[.size] as? Int64) ?? 0

        let docAttrs = doc.documentAttributes ?? [:]

        let title = docAttrs[PDFDocumentAttribute.titleAttribute] as? String
        let author = docAttrs[PDFDocumentAttribute.authorAttribute] as? String
        let subject = docAttrs[PDFDocumentAttribute.subjectAttribute] as? String
        let creator = docAttrs[PDFDocumentAttribute.creatorAttribute] as? String
        let producer = docAttrs[PDFDocumentAttribute.producerAttribute] as? String
        let creationDate = docAttrs[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modificationDate = docAttrs[PDFDocumentAttribute.modificationDateAttribute] as? Date
        let keywords = docAttrs[PDFDocumentAttribute.keywordsAttribute] as? [String]

        return PDFInfo(
            path: path,
            pageCount: doc.pageCount,
            versionMajor: doc.majorVersion,
            versionMinor: doc.minorVersion,
            fileSize: fileSize,
            fileSizeFormatted: OutputFormatter.formatFileSize(fileSize),
            isEncrypted: doc.isEncrypted,
            isLocked: doc.isLocked,
            title: title,
            author: author,
            subject: subject,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modificationDate,
            keywords: keywords
        )
    }

    private func buildOutlineEntries(from outline: PDFOutline, doc: PDFDocument,
                                     depth: Int) -> [PDFOutlineEntry] {
        var entries: [PDFOutlineEntry] = []

        for i in 0..<outline.numberOfChildren {
            guard let child = outline.child(at: i) else { continue }
            let title = child.label ?? ""
            var pageIndex: Int?
            var pageLabel: String?

            if let dest = child.destination, let page = dest.page {
                pageIndex = doc.index(for: page) + 1
                pageLabel = page.label
            }

            let children = buildOutlineEntries(from: child, doc: doc, depth: depth + 1)

            entries.append(PDFOutlineEntry(
                title: title,
                pageIndex: pageIndex,
                pageLabel: pageLabel,
                depth: depth,
                children: children
            ))
        }

        return entries
    }
}

public enum PDFError: LocalizedError {
    case invalidDocument(String)
    case pageOutOfRange(Int, Int)
    case documentLocked(String)
    case invalidRotation(Int)
    case writeFailed(String)
    case noTextFound
    case invalidPageRange(Int, Int, Int)

    public var errorDescription: String? {
        switch self {
        case .invalidDocument(let path):
            return "Cannot open PDF: \(path)"
        case .pageOutOfRange(let page, let total):
            return "Page \(page) out of range (document has \(total) pages)"
        case .documentLocked(let path):
            return "PDF is locked: \(path)"
        case .invalidRotation(let angle):
            return "Invalid rotation angle \(angle) (must be 0, 90, 180, or 270)"
        case .writeFailed(let path):
            return "Failed to write PDF: \(path)"
        case .noTextFound:
            return "No text found in document"
        case .invalidPageRange(let start, let end, let total):
            return "Invalid page range \(start)-\(end) (document has \(total) pages)"
        }
    }
}
