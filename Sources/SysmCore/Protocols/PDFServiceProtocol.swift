import Foundation

public protocol PDFServiceProtocol: Sendable {
    func info(path: String) throws -> PDFInfo
    func text(path: String, page: Int?) throws -> String
    func search(path: String, query: String, caseSensitive: Bool) throws -> [PDFSearchResult]
    func pages(path: String) throws -> [PDFPageInfo]
    func thumbnail(path: String, page: Int, outputPath: String, size: Int) throws
    func merge(paths: [String], outputPath: String) throws
    func split(path: String, pageRange: ClosedRange<Int>, outputPath: String) throws
    func rotate(path: String, pages: [Int], angle: Int, outputPath: String) throws
    func encrypt(path: String, ownerPassword: String, userPassword: String?, outputPath: String) throws
    func decrypt(path: String, password: String, outputPath: String) throws
    func metadata(path: String) throws -> PDFInfo
    func setMetadata(path: String, title: String?, author: String?, subject: String?,
                     keywords: [String]?, outputPath: String) throws
    func annotations(path: String, page: Int?) throws -> [PDFAnnotationInfo]
    func addAnnotation(path: String, page: Int, type: String, text: String,
                       x: Double, y: Double, outputPath: String) throws
    func watermark(path: String, text: String, fontSize: Double, opacity: Double,
                   angle: Double, outputPath: String) throws
    func compress(path: String, outputPath: String) throws
    func ocrEmbed(path: String, outputPath: String) throws
    func imagesToPDF(imagePaths: [String], outputPath: String) throws
    func outline(path: String) throws -> [PDFOutlineEntry]
    func permissions(path: String) throws -> PDFPermissions
}
