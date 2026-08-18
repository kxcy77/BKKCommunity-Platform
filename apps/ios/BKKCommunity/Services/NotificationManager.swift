import Foundation
import UserNotifications

public final class NotificationManager: Sendable {
    public static let shared = NotificationManager()
    
    private init() {}
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    public func scheduleNotification(for event: CommunityEvent) {
        requestAuthorization()
        
        let center = UNUserNotificationCenter.current()
        
        // Parse ISO date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        guard let eventDate = formatter.date(from: event.startAt) ?? fallbackFormatter.date(from: event.startAt) else { return }
        
        // 1. Notification 1 Hour Before
        let oneHourBefore = eventDate.addingTimeInterval(-3600)
        if oneHourBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = "⏰ Event Starting Soon: \(event.title)"
            content.body = "Starts in 1 hour at \(event.location). Don't forget to attend!"
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: oneHourBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "event-1h-\(event.id)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule 1h notification: \(error.localizedDescription)")
                }
            }
        }
        
        // 2. Notification 1 Day Before
        let oneDayBefore = eventDate.addingTimeInterval(-86400)
        if oneDayBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = "📅 Upcoming Event Tomorrow: \(event.title)"
            content.body = "Scheduled for tomorrow at \(event.location)."
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: oneDayBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "event-24h-\(event.id)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule 24h notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func cancelNotification(for eventID: Int64) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["event-1h-\(eventID)", "event-24h-\(eventID)"])
    }
}
