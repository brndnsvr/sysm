import ArgumentParser
import Foundation
import SysmCore

struct VMShare: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "share",
        abstract: "Manage shared directories (VirtioFS)",
        subcommands: [
            VMShareAdd.self,
            VMShareRemove.self,
            VMShareList.self,
        ]
    )
}

struct VMShareAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a shared directory to a VM"
    )

    @Argument(help: "VM name")
    var name: String

    @Option(name: .long, help: "Host directory path")
    var path: String

    @Option(name: .long, help: "Mount tag (used in guest: mount -t virtiofs <tag> /mnt)")
    var tag: String

    @Flag(name: .long, help: "Mount read-only in guest")
    var readOnly = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        try service.addSharedDirectory(name: name, hostPath: path, tag: tag, readOnly: readOnly)

        if json {
            try OutputFormatter.printJSON(["status": "added", "vm": name, "tag": tag, "path": path])
        } else {
            print("Added shared directory '\(tag)' -> \(path) to VM '\(name)'")
            print("  Mount in guest: mount -t virtiofs \(tag) /mnt/\(tag)")
        }
    }
}

struct VMShareRemove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a shared directory from a VM"
    )

    @Argument(help: "VM name")
    var name: String

    @Option(name: .long, help: "Mount tag to remove")
    var tag: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        try service.removeSharedDirectory(name: name, tag: tag)

        if json {
            try OutputFormatter.printJSON(["status": "removed", "vm": name, "tag": tag])
        } else {
            print("Removed shared directory '\(tag)' from VM '\(name)'")
        }
    }
}

struct VMShareList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ls",
        abstract: "List shared directories for a VM"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        let info = try service.getVMInfo(name: name)
        let dirs = info.sharedDirectories ?? []

        if json {
            try OutputFormatter.printJSON(dirs)
        } else {
            if dirs.isEmpty {
                print("No shared directories configured for VM '\(name)'")
            } else {
                print("Shared directories for VM '\(name)':\n")
                for dir in dirs {
                    let mode = dir.readOnly ? "read-only" : "read-write"
                    print("  [\(dir.tag)] \(dir.hostPath) (\(mode))")
                }
            }
        }
    }
}
