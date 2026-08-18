import Foundation

public struct DemoStore {
    public static let sampleEvents: [CommunityEvent] = [
        CommunityEvent(
            id: -1,
            title: "Morning Exercise Class",
            description: "A gentle, low-impact exercise session suitable for all fitness levels and mobility. Led by our qualified biokineticist.",
            startAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            endAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7200)),
            location: "Community Hall — Block B",
            directions: "Use the Block B entrance on the left side of the building. Chairs and mats provided.",
            category: "Exercise",
            colourHex: "#315C24",
            isAttending: false
        ),
        CommunityEvent(
            id: -2,
            title: "Social Lunch Gathering",
            description: "Share a light lunch and connect with other BKK community members. Tea and coffee served.",
            startAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 2)),
            endAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 2 + 5400)),
            location: "BKK Community Hall — Main Hall",
            directions: "Main entrance on Main Road. Parking available at the back.",
            category: "Social",
            colourHex: "#2E75B6",
            isAttending: false
        ),
        CommunityEvent(
            id: -3,
            title: "Health Talk: Managing Diabetes",
            description: "A practical information session on managing Type 2 diabetes through diet, exercise and medication.",
            startAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 4)),
            endAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 4 + 5400)),
            location: "BKK Clinic — Room 2",
            directions: "Enter through the clinic reception. Room 2 is down the corridor on the right.",
            category: "Health",
            colourHex: "#B00020",
            isAttending: false
        )
    ]

    public static let sampleDiscounts: [Discount] = [
        Discount(
            id: -1,
            storeName: "Clicks",
            title: "10% off selected prescriptions",
            details: "Senior members aged 60 and over receive a 10% discount on selected prescription and over-the-counter medication.",
            eligibility: "Customers aged 60 or older with a valid South African ID.",
            claimInstructions: "Present your ID at the pharmacy counter before payment.",
            category: "Pharmacy",
            validFrom: nil,
            validUntil: nil
        ),
        Discount(
            id: -2,
            storeName: "Checkers",
            title: "Tuesday Senior Savings — 5% off",
            details: "Every Tuesday, senior shoppers receive a 5% discount on qualifying grocery purchases.",
            eligibility: "Customers aged 60 or older.",
            claimInstructions: "Present your South African ID before the cashier processes payment.",
            category: "Grocery",
            validFrom: nil,
            validUntil: nil
        ),
        Discount(
            id: -3,
            storeName: "Wimpy",
            title: "Senior Breakfast Special before 10:00",
            details: "Enjoy a reduced-price breakfast when you arrive before 10:00 on weekdays.",
            eligibility: "Customers aged 60 or older.",
            claimInstructions: "Ask your server for the Senior Breakfast Menu.",
            category: "Restaurant",
            validFrom: nil,
            validUntil: nil
        )
    ]

    public static let sampleServices: [LocalService] = [
        LocalService(
            id: -1,
            type: "clinic",
            name: "BKK Community Clinic",
            address: "12 Main Road, BKK",
            phone: "011 555 0101",
            directions: "Directly opposite the BKK Community Hall.",
            openingHours: "Monday – Friday: 08:00 – 16:00"
        ),
        LocalService(
            id: -2,
            type: "pharmacy",
            name: "Community Pharmacy",
            address: "18 Main Road, BKK",
            phone: "011 555 0102",
            directions: "Next to the Pick n Pay grocery store.",
            openingHours: "Monday – Saturday: 08:00 – 18:00"
        ),
        LocalService(
            id: -3,
            type: "support",
            name: "BKK Community Support Desk",
            address: "BKK Community Hall, Main Road",
            phone: "072 888 5030",
            directions: "Reception desk inside the main entrance.",
            openingHours: "Weekdays: 09:00 – 15:00"
        )
    ]
}
