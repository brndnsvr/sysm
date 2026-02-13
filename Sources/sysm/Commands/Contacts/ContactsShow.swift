import ArgumentParser
import Foundation
import SysmCore

struct ContactsShow: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show full contact details"
    )

    @Argument(help: "Contact identifier")
    var identifier: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.contacts()

        guard let contact = try await service.getContact(identifier: identifier) else {
            fputs("Contact not found: \(identifier)\n", stderr)
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(contact)
        } else {
            print("\(contact.fullName)")
            print(String(repeating: "-", count: contact.fullName.count))

            if let org = contact.organization {
                if let title = contact.jobTitle {
                    print("\(title) at \(org)")
                } else {
                    print(org)
                }
            }

            if !contact.emails.isEmpty {
                print("\nEmail:")
                for email in contact.emails {
                    print("  \(email)")
                }
            }

            if !contact.phones.isEmpty {
                print("\nPhone:")
                for phone in contact.phones {
                    print("  \(phone)")
                }
            }

            if let addresses = contact.addresses, !addresses.isEmpty {
                print("\nAddress:")
                for address in addresses {
                    print("  \(address)")
                }
            }

            if let birthday = contact.birthday {
                print("\nBirthday: \(birthday)")
            }

            if let urls = contact.urls, !urls.isEmpty {
                print("\nURLs:")
                for url in urls {
                    print("  \(url)")
                }
            }

            if let profiles = contact.socialProfiles, !profiles.isEmpty {
                print("\nSocial Profiles:")
                for profile in profiles {
                    if let url = profile.url {
                        print("  \(profile.service): @\(profile.username) (\(url))")
                    } else {
                        print("  \(profile.service): @\(profile.username)")
                    }
                }
            }

            if let relations = contact.relations, !relations.isEmpty {
                print("\nRelations:")
                for relation in relations {
                    print("  \(relation.label): \(relation.name)")
                }
            }

            if let note = contact.note {
                print("\nNotes:")
                print("  \(note)")
            }

            print("\nID: \(contact.identifier)")
            if contact.hasPhoto {
                print("Photo: Yes (use 'contacts photo get \(contact.identifier) --output photo.jpg' to extract)")
            } else {
                print("Photo: No")
            }
        }
    }
}
