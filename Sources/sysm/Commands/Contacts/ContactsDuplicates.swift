import ArgumentParser
import Foundation
import SysmCore

struct ContactsDuplicates: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "duplicates",
        abstract: "Find potential duplicate contacts"
    )

    @Option(name: .long, help: "Similarity threshold (0.0-1.0, default: 0.8)")
    var similarity: Double = 0.8

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        if similarity < 0.0 || similarity > 1.0 {
            fputs("Error: Similarity must be between 0.0 and 1.0\n", stderr)
            throw ExitCode.failure
        }

        let service = Services.contacts()
        let duplicateGroups = try await service.findDuplicates(similarityThreshold: similarity)

        if json {
            try OutputFormatter.printJSON(duplicateGroups)
        } else {
            if duplicateGroups.isEmpty {
                print("No duplicate contacts found (threshold: \(String(format: "%.1f", similarity * 100))%)")
            } else {
                print("Found \(duplicateGroups.count) group(s) of potential duplicates:\n")

                for (groupIndex, group) in duplicateGroups.enumerated() {
                    print("Group \(groupIndex + 1) (\(group.count) contacts):")
                    for contact in group {
                        print("  \(contact.fullName) (ID: \(contact.identifier))")
                        if !contact.emails.isEmpty {
                            print("    Emails: \(contact.emails.joined(separator: ", "))")
                        }
                        if !contact.phones.isEmpty {
                            print("    Phones: \(contact.phones.joined(separator: ", "))")
                        }
                        if let org = contact.organization {
                            print("    Organization: \(org)")
                        }
                    }
                    print()
                }

                print("Use 'contacts merge <primary-id> <duplicate-id>' to merge contacts")
            }
        }
    }
}
