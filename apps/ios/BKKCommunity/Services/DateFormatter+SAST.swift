import Foundation

enum BKKDateFormatting {
    static let fractionalISO: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standardISO = ISO8601DateFormatter()

    static let southAfricanDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy 'at' HH:mm"
        formatter.timeZone = TimeZone(identifier: "Africa/Johannesburg") ?? .current
        formatter.locale = Locale(identifier: "en_ZA")
        return formatter
    }()

    static let today: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        formatter.locale = Locale(identifier: "en_ZA")
        return formatter
    }()

    static let eventMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    static let eventDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    static let eventTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func parseISO(_ value: String) -> Date? {
        fractionalISO.date(from: value) ?? standardISO.date(from: value)
    }
}

public extension String {
    func toSouthAfricanFormattedDate() -> String {
        guard let date = BKKDateFormatting.parseISO(self) else { return self }
        return BKKDateFormatting.southAfricanDateTime.string(from: date)
    }
}
