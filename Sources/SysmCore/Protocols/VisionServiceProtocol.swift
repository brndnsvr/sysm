import Foundation

public protocol VisionServiceProtocol: Sendable {
    func detectBarcodes(imagePath: String) throws -> [BarcodeResult]
    func detectFaces(imagePath: String) throws -> [FaceResult]
    func classifyImage(imagePath: String) throws -> [ClassificationResult]
    func detectRectangles(imagePath: String) throws -> [RectangleResult]
}
