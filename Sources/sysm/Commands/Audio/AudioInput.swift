import ArgumentParser
import SysmCore

struct AudioInput: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "input",
        abstract: "Show or set default input device"
    )

    @Argument(help: "Device name to set as default input")
    var deviceName: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()

        if let name = deviceName {
            try service.setDefaultInput(name: name)
            if json {
                try OutputFormatter.printJSON(["status": "set", "device": name])
            } else {
                print("Default input set to: \(name)")
            }
        } else {
            let device = try service.getDefaultInput()
            if json {
                try OutputFormatter.printJSON(device)
            } else {
                print("Default input: \(device.name)")
                if let uid = device.uid {
                    print("  UID: \(uid)")
                }
            }
        }
    }
}
