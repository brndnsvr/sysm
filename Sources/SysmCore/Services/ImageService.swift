import CoreImage
import Foundation
import ImageIO
import Vision

public struct ImageService: ImageServiceProtocol {
    public init() {}

    public func resize(inputPath: String, outputPath: String, width: Int?, height: Int?) throws {
        let expanded = expandPath(inputPath)
        let expandedOutput = expandPath(outputPath)

        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: expanded) as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageError.invalidImage(expanded)
        }

        let origWidth = cgImage.width
        let origHeight = cgImage.height

        let newWidth: Int
        let newHeight: Int

        if let w = width, let h = height {
            newWidth = w
            newHeight = h
        } else if let w = width {
            newWidth = w
            newHeight = Int(Double(origHeight) * Double(w) / Double(origWidth))
        } else if let h = height {
            newHeight = h
            newWidth = Int(Double(origWidth) * Double(h) / Double(origHeight))
        } else {
            throw ImageError.invalidDimensions
        }

        let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )

        guard let ctx = context else {
            throw ImageError.processingFailed("Failed to create graphics context")
        }

        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resized = ctx.makeImage() else {
            throw ImageError.processingFailed("Failed to create resized image")
        }

        try writeImage(resized, to: expandedOutput, format: formatFromPath(expandedOutput))
    }

    public func convert(inputPath: String, outputPath: String, format: ImageFormat) throws {
        let expanded = expandPath(inputPath)
        let expandedOutput = expandPath(outputPath)

        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: expanded) as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageError.invalidImage(expanded)
        }

        try writeImage(cgImage, to: expandedOutput, format: format)
    }

    public func ocr(imagePath: String) throws -> String {
        let expanded = expandPath(imagePath)
        let url = URL(fileURLWithPath: expanded)

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageError.invalidImage(expanded)
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return ""
        }

        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    public func metadata(imagePath: String) throws -> ImageMetadata {
        let expanded = expandPath(imagePath)
        let url = URL(fileURLWithPath: expanded)

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ImageError.invalidImage(expanded)
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]

        let width = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let colorSpace = properties[kCGImagePropertyColorModel as String] as? String
        let hasAlpha = properties[kCGImagePropertyHasAlpha as String] as? Bool ?? false

        var dpi: Int?
        if let dpiWidth = properties[kCGImagePropertyDPIWidth as String] as? Double {
            dpi = Int(dpiWidth)
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: expanded)
        let fileSize = (attrs[.size] as? Int64) ?? 0

        let uti = CGImageSourceGetType(source) as String?
        let format = uti.flatMap { formatName($0) }

        return ImageMetadata(
            path: expanded,
            width: width,
            height: height,
            colorSpace: colorSpace,
            fileSize: fileSize,
            fileSizeFormatted: OutputFormatter.formatFileSize(fileSize),
            format: format,
            dpi: dpi,
            hasAlpha: hasAlpha
        )
    }

    public func thumbnail(inputPath: String, outputPath: String, size: Int) throws {
        let expanded = expandPath(inputPath)
        let expandedOutput = expandPath(outputPath)

        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: expanded) as CFURL, nil) else {
            throw ImageError.invalidImage(expanded)
        }

        let options: [String: Any] = [
            kCGImageSourceThumbnailMaxPixelSize as String: size,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true,
            kCGImageSourceCreateThumbnailWithTransform as String: true,
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageError.processingFailed("Failed to create thumbnail")
        }

        try writeImage(thumbnail, to: expandedOutput, format: formatFromPath(expandedOutput))
    }

    // MARK: - Private

    private func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func writeImage(_ image: CGImage, to path: String, format: ImageFormat) throws {
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let url = URL(fileURLWithPath: path)
        let uti = utiForFormat(format)

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti as CFString, 1, nil) else {
            throw ImageError.processingFailed("Failed to create image destination")
        }

        var properties: [String: Any] = [:]
        if format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality as String] = 0.85
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageError.processingFailed("Failed to write image to \(path)")
        }
    }

    private func formatFromPath(_ path: String) -> ImageFormat {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return .jpeg
        case "tiff", "tif": return .tiff
        case "heif", "heic": return .heif
        default: return .png
        }
    }

    private func utiForFormat(_ format: ImageFormat) -> String {
        switch format {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        case .tiff: return "public.tiff"
        case .heif: return "public.heif"
        }
    }

    private func formatName(_ uti: String) -> String? {
        switch uti {
        case "public.png": return "PNG"
        case "public.jpeg": return "JPEG"
        case "public.tiff": return "TIFF"
        case "public.heif", "public.heic": return "HEIF"
        case "com.compuserve.gif": return "GIF"
        case "com.microsoft.bmp": return "BMP"
        case "public.webp": return "WebP"
        default: return uti
        }
    }
}

public enum ImageError: LocalizedError {
    case invalidImage(String)
    case invalidDimensions
    case processingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImage(let path):
            return "Cannot open image: \(path)"
        case .invalidDimensions:
            return "Must specify at least width or height"
        case .processingFailed(let msg):
            return "Image processing failed: \(msg)"
        }
    }
}
