import EventKit
import Foundation
import ArgumentParser

/// Event availability status.
public enum EventAvailability: String, Codable, CaseIterable, ExpressibleByArgument {
    case busy
    case free
    case tentative
    case unavailable

    public init(from ekAvailability: EKEventAvailability) {
        switch ekAvailability {
        case .notSupported: self = .busy
        case .busy: self = .busy
        case .free: self = .free
        case .tentative: self = .tentative
        case .unavailable: self = .unavailable
        @unknown default: self = .busy
        }
    }

    public var ekAvailability: EKEventAvailability {
        switch self {
        case .busy: return .busy
        case .free: return .free
        case .tentative: return .tentative
        case .unavailable: return .unavailable
        }
    }
}
