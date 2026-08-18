import Foundation
import SwiftUI

public struct CommunityEvent: Identifiable, Codable, Sendable, Equatable {
    public let id: Int64
    public let title: String
    public let description: String
    public let startAt: String
    public let endAt: String
    public let location: String
    public let directions: String?
    public let category: String
    public let colourHex: String
    public var isAttending: BooleanLiteralType

    enum CodingKeys: String, CodingKey {
        case id, title, description, location, directions, category
        case startAt = "start_at"
        case endAt = "end_at"
        case colourHex = "colour_hex"
        case isAttending = "is_attending"
    }

    public var isFree: Bool {
        return title.localizedCaseInsensitiveContains("free") || description.localizedCaseInsensitiveContains("free")
    }

    public var isDemonstration: Bool {
        category.equalsIgnoreCase("Demonstration")
            || title.localizedCaseInsensitiveContains("not a real event")
            || description.localizedCaseInsensitiveContains("test content only")
            || location.localizedCaseInsensitiveContains("do not travel")
    }

    public init(id: Int64, title: String, description: String, startAt: String, endAt: String, location: String, directions: String?, category: String, colourHex: String, isAttending: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.startAt = startAt
        self.endAt = endAt
        self.location = location
        self.directions = directions
        self.category = category
        self.colourHex = colourHex
        self.isAttending = isAttending
    }
}

public struct Discount: Identifiable, Codable, Sendable, Equatable {
    public let id: Int64
    public let storeName: String
    public let title: String
    public let details: String
    public let eligibility: String
    public let claimInstructions: String
    public let category: String
    public let validFrom: String?
    public let validUntil: String?

    enum CodingKeys: String, CodingKey {
        case id, title, details, eligibility, category
        case storeName = "store_name"
        case claimInstructions = "claim_instructions"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
    }

    public init(id: Int64, storeName: String, title: String, details: String, eligibility: String, claimInstructions: String, category: String, validFrom: String?, validUntil: String?) {
        self.id = id
        self.storeName = storeName
        self.title = title
        self.details = details
        self.eligibility = eligibility
        self.claimInstructions = claimInstructions
        self.category = category
        self.validFrom = validFrom
        self.validUntil = validUntil
    }
}

public struct LocalService: Identifiable, Codable, Sendable, Equatable {
    public let id: Int64
    public let type: String
    public let name: String
    public let address: String
    public let phone: String
    public let directions: String?
    public let openingHours: String?

    enum CodingKeys: String, CodingKey {
        case id, type, name, address, phone, directions
        case openingHours = "opening_hours"
    }

    public init(id: Int64, type: String, name: String, address: String, phone: String, directions: String?, openingHours: String?) {
        self.id = id
        self.type = type
        self.name = name
        self.address = address
        self.phone = phone
        self.directions = directions
        self.openingHours = openingHours
    }
}

public struct Member: Identifiable, Codable, Sendable, Equatable {
    public let id: Int64
    public let fullName: String
    public let email: String
    public let phone: String?
    public var notificationsEnabled: Bool
    public var eventRemindersEnabled: Bool
    public var discountAlertsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case fullName = "full_name"
        case notificationsEnabled = "notifications_enabled"
        case eventRemindersEnabled = "event_reminders_enabled"
        case discountAlertsEnabled = "discount_alerts_enabled"
    }

    public init(id: Int64, fullName: String, email: String, phone: String?, notificationsEnabled: Bool = true, eventRemindersEnabled: Bool = true, discountAlertsEnabled: Bool = true) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.notificationsEnabled = notificationsEnabled
        self.eventRemindersEnabled = eventRemindersEnabled
        self.discountAlertsEnabled = discountAlertsEnabled
    }
}

public struct AuthSession: Codable, Sendable {
    public let user: Member
    public let token: String
}

public struct APIEnvelope<T: Codable>: Codable {
    public let data: T
}

public extension String {
    func equalsIgnoreCase(_ other: String) -> Bool {
        return self.caseInsensitiveCompare(other) == .orderedSame
    }
}

#if canImport(UIKit)
import UIKit
public extension Color {
    static let appSecondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let appSystemBackground = Color(UIColor.systemBackground)
}
#else
public extension Color {
    static let appSecondarySystemBackground = Color.gray.opacity(0.15)
    static let appSystemBackground = Color.white
}
#endif
