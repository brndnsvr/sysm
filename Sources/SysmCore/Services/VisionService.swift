import Foundation
import ImageIO
import Vision

public struct VisionService: VisionServiceProtocol {
    public init() {}

    public func detectBarcodes(imagePath: String) throws -> [BarcodeResult] {
        let cgImage = try loadImage(path: imagePath)
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return [] }

        return observations.map { obs in
            let box = obs.boundingBox
            return BarcodeResult(
                symbology: obs.symbology.rawValue,
                payload: obs.payloadStringValue,
                boundingBox: BoundingBox(x: box.origin.x, y: box.origin.y, width: box.width, height: box.height),
                confidence: Double(obs.confidence)
            )
        }
    }

    public func detectFaces(imagePath: String) throws -> [FaceResult] {
        let cgImage = try loadImage(path: imagePath)
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return [] }

        return observations.map { obs in
            let box = obs.boundingBox
            return FaceResult(
                boundingBox: BoundingBox(x: box.origin.x, y: box.origin.y, width: box.width, height: box.height),
                confidence: Double(obs.confidence),
                roll: obs.roll?.doubleValue,
                yaw: obs.yaw?.doubleValue
            )
        }
    }

    public func classifyImage(imagePath: String) throws -> [ClassificationResult] {
        let cgImage = try loadImage(path: imagePath)
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return [] }

        return observations
            .filter { $0.confidence > 0.1 }
            .sorted { $0.confidence > $1.confidence }
            .map { obs in
                ClassificationResult(
                    identifier: obs.identifier,
                    confidence: Double(obs.confidence)
                )
            }
    }

    public func detectRectangles(imagePath: String) throws -> [RectangleResult] {
        let cgImage = try loadImage(path: imagePath)
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 10
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return [] }

        return observations.map { obs in
            let box = obs.boundingBox
            return RectangleResult(
                boundingBox: BoundingBox(x: box.origin.x, y: box.origin.y, width: box.width, height: box.height),
                topLeft: VisionPoint(x: obs.topLeft.x, y: obs.topLeft.y),
                topRight: VisionPoint(x: obs.topRight.x, y: obs.topRight.y),
                bottomLeft: VisionPoint(x: obs.bottomLeft.x, y: obs.bottomLeft.y),
                bottomRight: VisionPoint(x: obs.bottomRight.x, y: obs.bottomRight.y),
                confidence: Double(obs.confidence)
            )
        }
    }

    // MARK: - Private

    private func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func loadImage(path: String) throws -> CGImage {
        let expanded = expandPath(path)
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: expanded) as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw VisionError.invalidImage(expanded)
        }
        return cgImage
    }
}

public enum VisionError: LocalizedError {
    case invalidImage(String)
    case analysisUnavailable(String)
    case noResultsFound

    public var errorDescription: String? {
        switch self {
        case .invalidImage(let path):
            return "Cannot open image: \(path)"
        case .analysisUnavailable(let msg):
            return "Vision analysis unavailable: \(msg)"
        case .noResultsFound:
            return "No results found"
        }
    }
}
