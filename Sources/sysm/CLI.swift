import ArgumentParser
import Dispatch
import Foundation
import SysmCore

enum CLI {
    /// Resolves one protected secret-input selector into an owned source.
    static func secretSource(
        prompt: Bool = false,
        standardInput: Bool,
        fileDescriptor: Int?,
        defaultToPrompt: Bool,
        label: String
    ) throws -> SecretInputSource? {
        let selectionCount = (prompt ? 1 : 0)
            + (standardInput ? 1 : 0)
            + (fileDescriptor == nil ? 0 : 1)

        guard selectionCount <= 1 else {
            throw ValidationError(
                "Choose only one protected input source for \(label): prompt, stdin, or file descriptor"
            )
        }

        if let fileDescriptor {
            guard let descriptor = Int32(exactly: fileDescriptor), descriptor >= 3 else {
                throw ValidationError("\(label) file descriptor must be between 3 and \(Int32.max)")
            }
            return .fileDescriptor(descriptor)
        }
        if standardInput {
            return .standardInput
        }
        if prompt || defaultToPrompt {
            return .terminal
        }
        return nil
    }

    /// Prompts the user for confirmation and returns true if they accept.
    /// Accepts "y" or "yes" (case-insensitive). Anything else is treated as decline.
    static func confirm(_ message: String) -> Bool {
        print(message, terminator: "")
        guard let response = readLine()?.lowercased(),
              response == "y" || response == "yes" else {
            print("Cancelled")
            return false
        }
        return true
    }

    /// Async variant that moves the blocking readLine() off the cooperative thread pool.
    static func confirm(_ message: String) async -> Bool {
        print(message, terminator: "")
        let response: String? = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: readLine())
            }
        }
        guard let response = response?.lowercased(),
              response == "y" || response == "yes" else {
            print("Cancelled")
            return false
        }
        return true
    }

    /// Non-blocking async readline that moves the blocking call off the cooperative thread pool.
    static func readLineAsync(prompt: String? = nil) async -> String? {
        if let prompt { print(prompt, terminator: "") }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: readLine())
            }
        }
    }
}
