import ArgumentParser
import Foundation
import SysmCore

struct ContactsMerge: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "merge",
        abstract: "Merge two contacts, keeping the primary contact"
    )

    @Argument(help: "Primary contact identifier (this contact will be kept)")
    var primaryId: String

    @Argument(help: "Duplicate contact identifier (this contact will be deleted after merging)")
    var duplicateId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()

        // Get both contacts to show what will happen
        guard let primary = try await service.getContact(identifier: primaryId) else {
            fputs("Primary contact not found: \(primaryId)\n", stderr)
            throw ExitCode.failure
        }

        guard let duplicate = try await service.getContact(identifier: duplicateId) else {
            fputs("Duplicate contact not found: \(duplicateId)\n", stderr)
            throw ExitCode.failure
        }

        print("Merging contacts:")
        print("  Primary (KEEP): \(primary.fullName)")
        print("  Duplicate (DELETE): \(duplicate.fullName)")
        print()
        print("The duplicate contact will be deleted after merging its data into the primary contact.")
        print()

        // Perform merge
        let merged = try await service.mergeContacts(
            primaryIdentifier: primaryId,
            duplicateIdentifier: duplicateId
        )

        if json {
            try OutputFormatter.printJSON(merged)
        } else {
            print("Successfully merged contacts!")
            print()
            print("Merged contact:")
            print("  Name: \(merged.fullName)")
            print("  ID: \(merged.identifier)")
            if !merged.emails.isEmpty {
                print("  Emails: \(merged.emails.joined(separator: ", "))")
            }
            if !merged.phones.isEmpty {
                print("  Phones: \(merged.phones.joined(separator: ", "))")
            }
        }
    }
}
