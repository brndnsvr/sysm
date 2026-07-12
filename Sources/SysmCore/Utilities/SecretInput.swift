import Darwin
import Foundation

public enum SecretInputSource: Equatable, Hashable, Sendable {
    case terminal
    case standardInput
    case fileDescriptor(Int32)
}

public enum SecretInputError: Error, Equatable, LocalizedError {
    case invalidMaximumBytes
    case invalidFileDescriptor(Int32)
    case terminalInputNotAllowed
    case terminalUnavailable(Int32)
    case readFailed(Int32)
    case inputTooLong(maximumBytes: Int)
    case emptyInput
    case containsNUL
    case invalidUTF8

    public var errorDescription: String? {
        switch self {
        case .invalidMaximumBytes:
            return "Secret input maximum length must be greater than zero"
        case .invalidFileDescriptor(let descriptor):
            return "Secret input file descriptor must be 3 or greater (received \(descriptor))"
        case .terminalInputNotAllowed:
            return "Refusing echoed terminal input; use the secure prompt"
        case .terminalUnavailable(let code):
            return "Secure terminal input is unavailable: \(Self.posixMessage(code))"
        case .readFailed(let code):
            return "Failed to read secret input: \(Self.posixMessage(code))"
        case .inputTooLong(let maximumBytes):
            return "Secret input exceeds the \(maximumBytes)-byte limit"
        case .emptyInput:
            return "Secret input cannot be empty"
        case .containsNUL:
            return "Secret input cannot contain NUL bytes"
        case .invalidUTF8:
            return "Secret input must be valid UTF-8"
        }
    }

    private static func posixMessage(_ code: Int32) -> String {
        guard let message = strerror(code) else { return "POSIX error \(code)" }
        return String(cString: message)
    }
}

public protocol SecretInputReading: Sendable {
    func read(
        from source: SecretInputSource,
        prompt: String,
        maximumBytes: Int
    ) throws -> String
}

public struct SecretInputReader: SecretInputReading, Sendable {
    private let standardInputDescriptor: Int32

    public init(standardInputDescriptor: Int32 = STDIN_FILENO) {
        self.standardInputDescriptor = standardInputDescriptor
    }

    public func read(
        from source: SecretInputSource,
        prompt: String,
        maximumBytes: Int = 65_536
    ) throws -> String {
        guard maximumBytes > 0, maximumBytes < Int.max - 2 else {
            throw SecretInputError.invalidMaximumBytes
        }

        switch source {
        case .terminal:
            return try readFromTerminal(prompt: prompt, maximumBytes: maximumBytes)
        case .standardInput:
            return try readFromDescriptor(
                standardInputDescriptor,
                requireNonTerminal: true,
                maximumBytes: maximumBytes
            )
        case .fileDescriptor(let descriptor):
            guard descriptor >= 3 else {
                throw SecretInputError.invalidFileDescriptor(descriptor)
            }
            return try readFromDescriptor(
                descriptor,
                requireNonTerminal: true,
                maximumBytes: maximumBytes
            )
        }
    }

    private func readFromTerminal(prompt: String, maximumBytes: Int) throws -> String {
        // One extra byte detects input longer than the accepted maximum; the final
        // byte is reserved for readpassphrase's NUL terminator.
        var buffer = [CChar](repeating: 0, count: maximumBytes + 2)
        defer {
            buffer.withUnsafeMutableBytes { bytes in
                if let baseAddress = bytes.baseAddress {
                    _ = memset_s(baseAddress, bytes.count, 0, bytes.count)
                }
            }
        }

        let result: UnsafeMutablePointer<CChar>? = prompt.withCString { promptPointer in
            buffer.withUnsafeMutableBufferPointer { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else { return nil }
                return readpassphrase(
                    promptPointer,
                    baseAddress,
                    bufferPointer.count,
                    RPP_REQUIRE_TTY
                )
            }
        }

        guard result != nil else {
            throw SecretInputError.terminalUnavailable(errno)
        }

        let count = buffer.firstIndex(of: 0) ?? buffer.count
        guard count <= maximumBytes else {
            throw SecretInputError.inputTooLong(maximumBytes: maximumBytes)
        }
        guard count > 0 else {
            throw SecretInputError.emptyInput
        }

        var data = buffer.withUnsafeBytes { bytes in
            Data(bytes.prefix(count))
        }
        defer {
            if !data.isEmpty {
                data.resetBytes(in: 0..<data.count)
            }
        }
        guard let value = String(data: data, encoding: .utf8) else {
            throw SecretInputError.invalidUTF8
        }
        return value
    }

    private func readFromDescriptor(
        _ descriptor: Int32,
        requireNonTerminal: Bool,
        maximumBytes: Int
    ) throws -> String {
        let ownedDescriptor = dup(descriptor)
        guard ownedDescriptor >= 0 else {
            throw SecretInputError.readFailed(errno)
        }
        defer { close(ownedDescriptor) }

        if requireNonTerminal, isatty(ownedDescriptor) == 1 {
            throw SecretInputError.terminalInputNotAllowed
        }

        var data = Data()
        defer {
            if !data.isEmpty {
                data.resetBytes(in: 0..<data.count)
            }
        }

        var buffer = [UInt8](repeating: 0, count: min(4_096, maximumBytes + 1))
        defer {
            buffer.withUnsafeMutableBytes { bytes in
                if let baseAddress = bytes.baseAddress {
                    _ = memset_s(baseAddress, bytes.count, 0, bytes.count)
                }
            }
        }

        while true {
            let remaining = maximumBytes + 1 - data.count
            guard remaining > 0 else {
                throw SecretInputError.inputTooLong(maximumBytes: maximumBytes)
            }

            let requested = min(buffer.count, remaining)
            let count = buffer.withUnsafeMutableBytes { bytes in
                guard let baseAddress = bytes.baseAddress else { return 0 }
                return Darwin.read(ownedDescriptor, baseAddress, requested)
            }

            if count == 0 { break }
            if count < 0 {
                if errno == EINTR { continue }
                throw SecretInputError.readFailed(errno)
            }

            data.append(contentsOf: buffer.prefix(count))
            if data.count > maximumBytes {
                throw SecretInputError.inputTooLong(maximumBytes: maximumBytes)
            }
        }

        if data.last == 0x0A {
            data.removeLast()
            if data.last == 0x0D {
                data.removeLast()
            }
        }

        guard !data.isEmpty else {
            throw SecretInputError.emptyInput
        }
        guard !data.contains(0) else {
            throw SecretInputError.containsNUL
        }
        guard let value = String(data: data, encoding: .utf8) else {
            throw SecretInputError.invalidUTF8
        }
        return value
    }
}
