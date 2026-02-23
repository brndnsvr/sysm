import ArgumentParser
import SysmCore

struct AudioOutput: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "output",
        abstract: "Show or set default output device"
    )

    @Argument(help: "Device name to set as default output")
    var deviceName: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()

        if let name = deviceName {
            try service.setDefaultOutput(name: name)
            if json {
                try OutputFormatter.printJSON(["status": "set", "device": name])
            } else {
                print("Default output set to: \(name)")
            }
        } else {
            let device = try service.getDefaultOutput()
            if json {
                try OutputFormatter.printJSON(device)
            } else {
                print("Default output: \(device.name)")
                if let uid = device.uid {
                    print("  UID: \(uid)")
                }
            }
        }
    }
}
