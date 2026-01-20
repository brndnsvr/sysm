import ArgumentParser
import Foundation
import SysmCore

struct PhotosMetadata: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "metadata",
        abstract: "Show metadata and EXIF info for a photo or video"
    )

    @Argument(help: "Asset ID (use 'sysm photos list --json' to find IDs)")
    var assetId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()

        do {
            let metadata = try await service.getMetadata(assetId: assetId)

            if json {
                try OutputFormatter.printJSON(metadata)
            } else {
                print("\(metadata.filename)")
                print(String(repeating: "-", count: metadata.filename.count))

                print("\nBasic Info:")
                print("  Type: \(metadata.mediaType)")
                print("  Dimensions: \(metadata.width) x \(metadata.height)")
                if let size = metadata.fileSize {
                    print("  File Size: \(formatFileSize(size))")
                }
                if let duration = metadata.duration {
                    print("  Duration: \(formatDuration(duration))")
                }

                print("\nDates:")
                if let created = metadata.creationDate {
                    print("  Created: \(DateFormatters.fullDateTime.string(from: created))")
                }
                if let modified = metadata.modificationDate {
                    print("  Modified: \(DateFormatters.fullDateTime.string(from: modified))")
                }

                if let location = metadata.locationString {
                    print("\nLocation:")
                    print("  Coordinates: \(location)")
                    if let altitude = metadata.altitude {
                        print("  Altitude: \(String(format: "%.1f m", altitude))")
                    }
                }

                if metadata.cameraMake != nil || metadata.cameraModel != nil {
                    print("\nCamera:")
                    if let make = metadata.cameraMake {
                        print("  Make: \(make)")
                    }
                    if let model = metadata.cameraModel {
                        print("  Model: \(model)")
                    }
                    if let lens = metadata.lensModel {
                        print("  Lens: \(lens)")
                    }
                }

                if metadata.focalLength != nil || metadata.aperture != nil || metadata.iso != nil || metadata.exposureTime != nil {
                    print("\nExposure:")
                    if let focal = metadata.focalLength {
                        print("  Focal Length: \(String(format: "%.1f mm", focal))")
                    }
                    if let aperture = metadata.apertureString {
                        print("  Aperture: \(aperture)")
                    }
                    if let iso = metadata.iso {
                        print("  ISO: \(iso)")
                    }
                    if let exposure = metadata.exposureString {
                        print("  Shutter Speed: \(exposure)")
                    }
                }

                var flags: [String] = []
                if metadata.isFavorite { flags.append("Favorite") }
                if metadata.isHidden { flags.append("Hidden") }
                if metadata.isBurst { flags.append("Burst") }
                if metadata.isScreenshot { flags.append("Screenshot") }
                if metadata.isLivePhoto { flags.append("Live Photo") }
                if metadata.isHDR { flags.append("HDR") }

                if !flags.isEmpty {
                    print("\nFlags: \(flags.joined(separator: ", "))")
                }

                print("\nID: \(metadata.id)")
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
