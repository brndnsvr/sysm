import Foundation

public protocol ImageServiceProtocol: Sendable {
    func resize(inputPath: String, outputPath: String, width: Int?, height: Int?) throws
    func convert(inputPath: String, outputPath: String, format: ImageFormat) throws
    func ocr(imagePath: String) throws -> String
    func metadata(imagePath: String) throws -> ImageMetadata
    func thumbnail(inputPath: String, outputPath: String, size: Int) throws
}
