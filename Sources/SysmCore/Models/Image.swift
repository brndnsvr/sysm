import Foundation

public enum ImageFormat: String, Codable, Sendable, CaseIterable {
    case png
    case jpeg
    case tiff
    case heif
}

public struct ImageMetadata: Codable, Sendable {
    public let path: String
    public let width: Int
    public let height: Int
    public let colorSpace: String?
    public let fileSize: Int64
    public let fileSizeFormatted: String
    public let format: String?
    public let dpi: Int?
    public let hasAlpha: Bool

    public init(path: String, width: Int, height: Int, colorSpace: String?, fileSize: Int64,
                fileSizeFormatted: String, format: String?, dpi: Int?, hasAlpha: Bool) {
        self.path = path
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.fileSize = fileSize
        self.fileSizeFormatted = fileSizeFormatted
        self.format = format
        self.dpi = dpi
        self.hasAlpha = hasAlpha
    }
}
