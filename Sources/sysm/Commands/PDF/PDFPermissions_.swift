import ArgumentParser
import Foundation
import SysmCore

struct PDFPermissions_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "permissions",
        abstract: "Show PDF permission flags"
    )

    @Argument(help: "PDF file path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.pdf()
        let perms = try service.permissions(path: input)

        if json {
            try OutputFormatter.printJSON(perms)
        } else {
            print("Permissions:")
            print("  Printing: \(perms.printing ? "Allowed" : "Denied")")
            print("  Copying: \(perms.copying ? "Allowed" : "Denied")")
            print("  Content Accessibility: \(perms.contentAccessibility ? "Allowed" : "Denied")")
            print("  Commenting: \(perms.commenting ? "Allowed" : "Denied")")
        }
    }
}
