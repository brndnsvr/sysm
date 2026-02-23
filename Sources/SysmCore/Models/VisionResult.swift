import Foundation

public struct BarcodeResult: Codable, Sendable {
    public let symbology: String
    public let payload: String?
    public let boundingBox: BoundingBox
    public let confidence: Double

    public init(symbology: String, payload: String?, boundingBox: BoundingBox, confidence: Double) {
        self.symbology = symbology
        self.payload = payload
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

public struct FaceResult: Codable, Sendable {
    public let boundingBox: BoundingBox
    public let confidence: Double
    public let roll: Double?
    public let yaw: Double?

    public init(boundingBox: BoundingBox, confidence: Double, roll: Double?, yaw: Double?) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.roll = roll
        self.yaw = yaw
    }
}

public struct ClassificationResult: Codable, Sendable {
    public let identifier: String
    public let confidence: Double

    public init(identifier: String, confidence: Double) {
        self.identifier = identifier
        self.confidence = confidence
    }
}

public struct RectangleResult: Codable, Sendable {
    public let boundingBox: BoundingBox
    public let topLeft: VisionPoint
    public let topRight: VisionPoint
    public let bottomLeft: VisionPoint
    public let bottomRight: VisionPoint
    public let confidence: Double

    public init(boundingBox: BoundingBox, topLeft: VisionPoint, topRight: VisionPoint,
                bottomLeft: VisionPoint, bottomRight: VisionPoint, confidence: Double) {
        self.boundingBox = boundingBox
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.confidence = confidence
    }
}

public struct BoundingBox: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct VisionPoint: Codable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
