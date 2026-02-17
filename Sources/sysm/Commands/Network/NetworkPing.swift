import ArgumentParser
import Foundation
import SysmCore

struct NetworkPing: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ping",
        abstract: "Ping a host"
    )

    @Argument(help: "Host to ping")
    var host: String

    @Option(name: .shortAndLong, help: "Number of packets to send")
    var count: Int = 4

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        let result = try service.ping(host: host, count: count)

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print("Ping \(result.host):")
            print("  Packets: \(result.packetsTransmitted) sent, \(result.packetsReceived) received")
            print("  Loss: \(String(format: "%.1f", result.packetLoss))%")
            if let min = result.roundTripMin,
               let avg = result.roundTripAvg,
               let max = result.roundTripMax {
                print("  RTT: min=\(String(format: "%.1f", min))ms avg=\(String(format: "%.1f", avg))ms max=\(String(format: "%.1f", max))ms")
            }
        }
    }
}
