import ArgumentParser
import Foundation

struct PhotosSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search photos by date range"
    )

    @Option(name: .long, help: "Start date (YYYY-MM-DD)")
    var from: String

    @Option(name: .long, help: "End date (YYYY-MM-DD)")
    var to: String

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int = 50

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let fromDate = formatter.date(from: from) else {
            throw ValidationError("Invalid from date. Use YYYY-MM-DD format.")
        }

        guard var toDate = formatter.date(from: to) else {
            throw ValidationError("Invalid to date. Use YYYY-MM-DD format.")
        }

        // Set to end of day
        toDate = Calendar.current.date(byAdding: .day, value: 1, to: toDate)!.addingTimeInterval(-1)

        let service = PhotosService()
        let photos = try await service.searchByDate(from: fromDate, to: toDate, limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(photos)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if photos.isEmpty {
                print("No photos found between \(from) and \(to)")
            } else {
                print("Photos from \(from) to \(to) (\(photos.count)):\n")
                for photo in photos {
                    print("  - \(photo.formatted())")
                    print("    ID: \(photo.id)")
                }
            }
        }
    }
}
