//
//  NoFollowFileWriter.swift
//  sysm
//

import Darwin
import Foundation

public enum NoFollowFileWriterError: LocalizedError, Equatable {
    case invalidDestination
    case openParentFailed(Int32)
    case openDestinationFailed(Int32)
    case destinationMetadataFailed(Int32)
    case unsupportedDestinationType
    case truncateFailed(Int32)
    case writeFailed(Int32)
    case closeFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .invalidDestination:
            "Invalid destination filename"
        case .openParentFailed(let code):
            "Could not open destination directory: \(Self.message(for: code))"
        case .openDestinationFailed(let code):
            "Could not safely open destination file: \(Self.message(for: code))"
        case .destinationMetadataFailed(let code):
            "Could not inspect destination file: \(Self.message(for: code))"
        case .unsupportedDestinationType:
            "Destination must be a regular file"
        case .truncateFailed(let code):
            "Could not truncate destination file: \(Self.message(for: code))"
        case .writeFailed(let code):
            "Could not write destination file: \(Self.message(for: code))"
        case .closeFailed(let code):
            "Could not finish destination file: \(Self.message(for: code))"
        }
    }

    private static func message(for code: Int32) -> String {
        String(cString: strerror(code))
    }
}

public enum NoFollowFileWriter {
    public static func write(_ data: Data, to url: URL) throws {
        let destination = url.standardizedFileURL
        let filename = destination.lastPathComponent
        guard !filename.isEmpty, filename != ".", filename != ".." else {
            throw NoFollowFileWriterError.invalidDestination
        }

        let parent = destination.deletingLastPathComponent()
        let parentFD = Darwin.open(parent.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard parentFD >= 0 else {
            throw NoFollowFileWriterError.openParentFailed(errno)
        }
        defer { Darwin.close(parentFD) }

        let flags = O_WRONLY | O_CREAT | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK
        var destinationFD = filename.withCString {
            Darwin.openat(parentFD, $0, flags, mode_t(0o600))
        }
        guard destinationFD >= 0 else {
            throw NoFollowFileWriterError.openDestinationFailed(errno)
        }

        do {
            var metadata = stat()
            guard Darwin.fstat(destinationFD, &metadata) == 0 else {
                throw NoFollowFileWriterError.destinationMetadataFailed(errno)
            }
            guard metadata.st_mode & S_IFMT == S_IFREG else {
                throw NoFollowFileWriterError.unsupportedDestinationType
            }
            guard Darwin.ftruncate(destinationFD, 0) == 0 else {
                throw NoFollowFileWriterError.truncateFailed(errno)
            }

            try writeAll(data, to: destinationFD)
            guard Darwin.close(destinationFD) == 0 else {
                let code = errno
                destinationFD = -1
                throw NoFollowFileWriterError.closeFailed(code)
            }
            destinationFD = -1
        } catch {
            if destinationFD >= 0 {
                Darwin.close(destinationFD)
            }
            throw error
        }
    }

    private static func writeAll(_ data: Data, to fileDescriptor: Int32) throws {
        try data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            var offset = 0

            while offset < bytes.count {
                let written = Darwin.write(
                    fileDescriptor,
                    baseAddress.advanced(by: offset),
                    bytes.count - offset
                )
                if written < 0 {
                    if errno == EINTR {
                        continue
                    }
                    throw NoFollowFileWriterError.writeFailed(errno)
                }
                guard written > 0 else {
                    throw NoFollowFileWriterError.writeFailed(EIO)
                }
                offset += written
            }
        }
    }
}
