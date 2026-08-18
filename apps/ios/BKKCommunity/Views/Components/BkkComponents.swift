import SwiftUI

// MARK: - Top Navigation Bar
public struct BkkTopBar: View {
    public let title: String
    public var onBack: (() -> Void)? = nil
    public var onProfile: (() -> Void)? = nil
    public var onNotifications: (() -> Void)? = nil
    public var unreadCount: Int = 0

    public init(
        title: String,
        onBack: (() -> Void)? = nil,
        onProfile: (() -> Void)? = nil,
        onNotifications: (() -> Void)? = nil,
        unreadCount: Int = 0
    ) {
        self.title = title
        self.onBack = onBack
        self.onProfile = onProfile
        self.onNotifications = onNotifications
        self.unreadCount = unreadCount
    }

    public var body: some View {
        ZStack {
            BkkTheme.topBarGradient
                .ignoresSafeArea(edges: .top)

            HStack(spacing: 12) {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if let onNotifications = onNotifications {
                    Button(action: onNotifications) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                            
                            if unreadCount > 0 {
                                Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.bkkRed)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: 2)
                            }
                        }
                    }
                }

                if let onProfile = onProfile {
                    Button(action: onProfile) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 42, height: 42)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 64)
    }
}

// MARK: - Section Title
public struct SectionTitle: View {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.bkkGold)
                .frame(width: 5, height: 26)

            Text(text)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.bkkNavy)
            
            Spacer()
        }
    }
}

// MARK: - Demo Content Notice Banner
public struct DemoContentNotice: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bkkGold.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: "icloud.slash.fill")
                    .foregroundColor(Color(hex: "#6A4000"))
            }

            Text("Demo information — connect the BKK server for live updates.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#5E3900"))

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.bkkGoldSurface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.bkkGold.opacity(0.28), lineWidth: 1)
        )
    }
}

// MARK: - Action Tile (Quick Navigation)
public struct ActionTile: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let color: Color
    public let surface: Color

    public init(
        title: String,
        subtitle: String,
        iconName: String,
        color: Color,
        surface: Color
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.color = color
        self.surface = surface
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color)
                            .frame(width: 48, height: 48)
                        Image(systemName: iconName)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    }
                }

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.bkkInk)

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.bkkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .leading)
        .background(surface)
        .cornerRadius(24)
        .overlay(
            RoundedCornerShape(radius: 24)
                .stroke(color.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Event Card
public struct EventCard: View {
    public let event: CommunityEvent
    public let onAttendance: (Bool) -> Void
    public var isSaved: Bool = false
    public var onToggleSaved: (() -> Void)? = nil

    public init(
        event: CommunityEvent,
        onAttendance: @escaping (Bool) -> Void,
        isSaved: Bool = false,
        onToggleSaved: (() -> Void)? = nil
    ) {
        self.event = event
        self.onAttendance = onAttendance
        self.isSaved = isSaved
        self.onToggleSaved = onToggleSaved
    }

    private var categoryColor: Color {
        Color(hex: event.colourHex)
    }

    private var formattedDateComponents: (month: String, day: String) {
        let date = BKKDateFormatting.parseISO(event.startAt) ?? Date()
        return (
            BKKDateFormatting.eventMonth.string(from: date),
            BKKDateFormatting.eventDay.string(from: date)
        )
    }

    private var formattedTimeRange: String {
        let startDate = BKKDateFormatting.parseISO(event.startAt) ?? Date()
        let endDate = BKKDateFormatting.parseISO(event.endAt) ?? Date()
        return "\(BKKDateFormatting.eventTime.string(from: startDate)) – \(BKKDateFormatting.eventTime.string(from: endDate))"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                // Date Block Pill
                VStack(spacing: 2) {
                    Text(formattedDateComponents.month.uppercased())
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    Text(formattedDateComponents.day)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(categoryColor)
                .cornerRadius(18)

                // Title & Category Tag
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.bkkInk)
                        .lineLimit(2)

                    Text(event.category)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.12))
                        .foregroundColor(categoryColor)
                        .cornerRadius(12)
                }

                Spacer()

                if let onToggleSaved = onToggleSaved {
                    Button(action: onToggleSaved) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                            .foregroundColor(.bkkBlue)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            // Time Row
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.bkkNavy)
                Text(formattedTimeRange)
                    .font(.system(size: 16))
                    .foregroundColor(.bkkInk)
            }

            // Location Row
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.bkkNavy)
                Text(event.location)
                    .font(.system(size: 16))
                    .foregroundColor(.bkkInk)
                    .lineLimit(1)
            }

            Divider()
                .background(Color.bkkLine)

            if event.isDemonstration {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Demonstration only")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Attendance is unavailable for this test event.")
                        .font(.body)
                }
                .foregroundColor(Color(hex: "#5E3900"))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bkkGoldSurface)
                .cornerRadius(16)
                .accessibilityElement(children: .combine)
            } else {
                Button(action: {
                    onAttendance(!event.isAttending)
                }) {
                    Text(event.isAttending ? "Attending ✓" : "I will attend")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(event.isAttending ? Color.bkkGreen : Color.bkkBlue)
                        .cornerRadius(16)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedCornerShape(radius: 24)
                .stroke(Color.bkkLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Discount Card
public struct DiscountCard: View {
    public let discount: Discount
    public var isSaved: Bool = false
    public var onToggleSaved: (() -> Void)? = nil

    public init(
        discount: Discount,
        isSaved: Bool = false,
        onToggleSaved: (() -> Void)? = nil
    ) {
        self.discount = discount
        self.isSaved = isSaved
        self.onToggleSaved = onToggleSaved
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bkkBlue)
                        .frame(width: 48, height: 48)
                    Image(systemName: "tag.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(discount.storeName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.bkkInk)

                    Text(discount.category)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.bkkBlue.opacity(0.12))
                        .foregroundColor(.bkkBlue)
                        .cornerRadius(12)
                }

                Spacer()

                if let onToggleSaved = onToggleSaved {
                    Button(action: onToggleSaved) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                            .foregroundColor(.bkkBlue)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            Text(discount.title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.bkkNavy)

            Text(discount.details)
                .font(.system(size: 15))
                .foregroundColor(.bkkMuted)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.bkkGold)
                    Text("Eligibility: \(discount.eligibility)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#5E3900"))
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.bkkBlue)
                    Text("How to claim: \(discount.claimInstructions)")
                        .font(.system(size: 14))
                        .foregroundColor(.bkkInk)
                }
            }
            .padding(12)
            .background(Color.bkkGoldSurface.opacity(0.6))
            .cornerRadius(14)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedCornerShape(radius: 22)
                .stroke(Color.bkkLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Service Card
public struct ServiceCard: View {
    public let service: LocalService
    public var isSaved: Bool = false
    public var onToggleSaved: (() -> Void)? = nil

    public init(
        service: LocalService,
        isSaved: Bool = false,
        onToggleSaved: (() -> Void)? = nil
    ) {
        self.service = service
        self.isSaved = isSaved
        self.onToggleSaved = onToggleSaved
    }

    private var typeIcon: String {
        switch service.type.lowercased() {
        case "clinic": return "cross.case.fill"
        case "pharmacy": return "cross.fill"
        default: return "building.2.fill"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bkkTeal)
                        .frame(width: 48, height: 48)
                    Image(systemName: typeIcon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.bkkInk)

                    Text(service.type.capitalized)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.bkkTeal.opacity(0.12))
                        .foregroundColor(.bkkTeal)
                        .cornerRadius(12)
                }

                Spacer()

                if let onToggleSaved = onToggleSaved {
                    Button(action: onToggleSaved) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20))
                            .foregroundColor(.bkkTeal)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.bkkTeal)
                Text(service.address)
                    .font(.system(size: 15))
                    .foregroundColor(.bkkInk)
            }

            if let hours = service.openingHours {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.bkkTeal)
                    Text(hours)
                        .font(.system(size: 15))
                        .foregroundColor(.bkkMuted)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: "tel://\(service.phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call Service")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.bkkTeal)
                    .cornerRadius(14)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: {
                    let query = service.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.bkkTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.bkkTealSurface)
                    .cornerRadius(14)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedCornerShape(radius: 22)
                .stroke(Color.bkkLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Rounded Corner Shape Helper
struct RoundedCornerShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
