import Foundation
import Combine
import SwiftUI

@MainActor
public final class BKKViewModel: ObservableObject {
    @Published public var events: [CommunityEvent] = []
    @Published public var discounts: [Discount] = []
    @Published public var services: [LocalService] = []
    @Published public var currentMember: Member? = nil
    @Published public var attendanceHistory: [CommunityEvent] = []
    @Published public var savedEventIDs: Set<Int64> = []
    @Published public var savedDiscountIDs: Set<Int64> = []
    @Published public var savedServiceIDs: Set<Int64> = []
    @Published public var selectedEventCategory: String = "All"
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false
    @Published public private(set) var isRestoringSession: Bool = false
    @Published public var statusMessage: String? = nil

    @Published public var selectedDiscountCategory: String = "All"
    @Published public var selectedServiceType: String = "All"
    @Published public var isFreeOnly: Bool = false

    public init() {
        loadOfflineCache()
        loadSavedItems()
        restoreSession()
    }

    public var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }

    public var filteredEvents: [CommunityEvent] {
        events.filter { event in
            let matchesCategory = (selectedEventCategory == "All" || event.category.equalsIgnoreCase(selectedEventCategory))
            let matchesSearch = searchText.isEmpty ||
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            let matchesPrice = !isFreeOnly || event.isFree
            return matchesCategory && matchesSearch && matchesPrice
        }
    }

    public var upcomingEvents: [CommunityEvent] {
        let now = Date()
        
        return events.filter { event in
            let date = BKKDateFormatting.parseISO(event.endAt) ?? Date.distantPast
            return date >= now
        }.sorted { event1, event2 in
            let date1 = BKKDateFormatting.parseISO(event1.startAt) ?? Date.distantPast
            let date2 = BKKDateFormatting.parseISO(event2.startAt) ?? Date.distantPast
            return date1 < date2
        }
    }


    public var filteredDiscounts: [Discount] {
        discounts.filter { discount in
            let matchesCategory = (selectedDiscountCategory == "All" || discount.category.equalsIgnoreCase(selectedDiscountCategory))
            let matchesSearch = searchText.isEmpty ||
                discount.title.localizedCaseInsensitiveContains(searchText) ||
                discount.storeName.localizedCaseInsensitiveContains(searchText) ||
                discount.details.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    public var filteredServices: [LocalService] {
        services.filter { service in
            let matchesType = (selectedServiceType == "All" || service.type.equalsIgnoreCase(selectedServiceType))
            let matchesSearch = searchText.isEmpty ||
                service.name.localizedCaseInsensitiveContains(searchText) ||
                service.address.localizedCaseInsensitiveContains(searchText) ||
                service.type.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    @Published public var isConnectedToBackend: Bool = false
    @Published public var eventRemindersEnabled: Bool = true
    @Published public var discountAlertsEnabled: Bool = true
    @Published public var announcementsEnabled: Bool = true

    private var contentLoadTask: Task<Void, Never>?

    private func loadOfflineCache() {
        if let data = UserDefaults.standard.data(forKey: "cached_events"),
           let cached = try? JSONDecoder().decode([CommunityEvent].self, from: data) {
            self.events = cached
        }
        if let data = UserDefaults.standard.data(forKey: "cached_discounts"),
           let cached = try? JSONDecoder().decode([Discount].self, from: data) {
            self.discounts = cached
        }
        if let data = UserDefaults.standard.data(forKey: "cached_services"),
           let cached = try? JSONDecoder().decode([LocalService].self, from: data) {
            self.services = cached
        }
    }

    private func saveOfflineCache() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "cached_events")
        }
        if let data = try? JSONEncoder().encode(discounts) {
            UserDefaults.standard.set(data, forKey: "cached_discounts")
        }
        if let data = try? JSONEncoder().encode(services) {
            UserDefaults.standard.set(data, forKey: "cached_services")
        }
    }

    public func loadData() {
        // Multiple view updates can ask for the same refresh. Keep one network
        // batch in flight instead of duplicating all three requests.
        guard contentLoadTask == nil else { return }

        isLoading = true
        contentLoadTask = Task { [weak self] in
            guard let self else { return }

            defer {
                self.isLoading = false
                self.contentLoadTask = nil
            }

            do {
                // These independent requests must overlap. Running them serially
                // multiplied the latency of the production Railway service.
                async let fetchedEvents = APIClient.shared.fetchEvents()
                async let fetchedDiscounts = APIClient.shared.fetchDiscounts()
                async let fetchedServices = APIClient.shared.fetchServices()
                let (events, discounts, services) = try await (
                    fetchedEvents,
                    fetchedDiscounts,
                    fetchedServices
                )

                guard !Task.isCancelled else { return }
                
                self.events = events
                self.discounts = discounts
                self.services = services
                self.isConnectedToBackend = true
                self.saveOfflineCache()
            } catch is CancellationError {
                return
            } catch {
                if self.events.isEmpty {
                    self.events = DemoStore.sampleEvents
                    self.discounts = DemoStore.sampleDiscounts
                    self.services = DemoStore.sampleServices
                }
                self.isConnectedToBackend = false
            }
        }
    }

    public func toggleSavedEvent(id: Int64) {
        if savedEventIDs.contains(id) {
            savedEventIDs.remove(id)
        } else {
            savedEventIDs.insert(id)
        }
        saveSavedItems()
    }

    public func toggleSavedDiscount(id: Int64) {
        if savedDiscountIDs.contains(id) {
            savedDiscountIDs.remove(id)
        } else {
            savedDiscountIDs.insert(id)
        }
        saveSavedItems()
    }

    public func toggleSavedService(id: Int64) {
        if savedServiceIDs.contains(id) {
            savedServiceIDs.remove(id)
        } else {
            savedServiceIDs.insert(id)
        }
        saveSavedItems()
    }

    public func toggleAttendance(eventID: Int64) {
        guard let event = events.first(where: { $0.id == eventID }) else {
            statusMessage = "This event is no longer available."
            return
        }
        guard !event.isDemonstration else {
            statusMessage = "This demonstration event cannot accept attendance."
            return
        }
        guard currentMember != nil else {
            statusMessage = "Please sign in before confirming attendance."
            return
        }
        if let index = events.firstIndex(where: { $0.id == eventID }) {
            let attending = !events[index].isAttending
            Task {
                do {
                    try await APIClient.shared.toggleAttendance(eventID: eventID, isAttending: attending)
                    guard let currentIndex = self.events.firstIndex(where: { $0.id == eventID }) else { return }
                    self.events[currentIndex].isAttending = attending
                    if attending {
                        NotificationManager.shared.scheduleNotification(for: event)
                        self.statusMessage = "Attendance confirmed. Event reminder scheduled."
                    } else {
                        NotificationManager.shared.cancelNotification(for: eventID)
                        self.statusMessage = "Attendance cancelled."
                    }
                    self.loadAttendanceHistory()
                } catch {
                    self.statusMessage = "Attendance was not changed: \(error.localizedDescription)"
                }
            }
        }
    }

    public func login(email: String, password: String) async throws {
        let member = try await APIClient.shared.login(email: email, password: password)
        applyMember(member)
        statusMessage = "Welcome back, \(member.fullName)."
    }

    public func register(name: String, email: String, phone: String?, password: String) async throws {
        let member = try await APIClient.shared.register(name: name, email: email, phone: phone, password: password)
        applyMember(member)
        statusMessage = "Account created. Welcome to BKK Community."
    }

    public func signOut() {
        contentLoadTask?.cancel()
        contentLoadTask = nil
        isLoading = false
        // APIClient clears Keychain synchronously, so killing the app during the
        // server revocation request cannot restore a session the user signed out of.
        APIClient.shared.logout()
        currentMember = nil
        attendanceHistory = []
        statusMessage = nil
    }

    public func requestPasswordReset(email: String) async throws {
        try await APIClient.shared.requestPasswordReset(email: email)
    }

    public func submitPasswordReset(email: String, token: String, newPassword: String) async throws {
        try await APIClient.shared.submitPasswordReset(email: email, token: token, newPassword: newPassword)
    }

    public func saveNotificationPreferences() {
        Task {
            do {
                let member = try await APIClient.shared.updateNotificationPreferences(
                    notifications: announcementsEnabled,
                    eventReminders: eventRemindersEnabled,
                    discountAlerts: discountAlertsEnabled
                )
                self.applyMember(member)
                self.statusMessage = "Notification preferences updated."
            } catch {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    public func updateProfile(name: String, email: String, phone: String?) {
        Task {
            do {
                self.applyMember(try await APIClient.shared.updateProfile(name: name, email: email, phone: phone))
                self.statusMessage = "Profile updated."
            } catch {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    public func submitContact(name: String, email: String, message: String) {
        Task {
            do {
                try await APIClient.shared.submitContact(name: name, email: email, message: message)
                self.statusMessage = "Thank you. Your message has been received."
            } catch {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    public func loadAttendanceHistory() {
        guard currentMember != nil else { return }
        Task {
            do {
                self.attendanceHistory = try await APIClient.shared.fetchAttendanceHistory()
            } catch {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    public func deleteAccount() {
        Task {
            do {
                try await APIClient.shared.deleteAccount()
                self.currentMember = nil
                self.attendanceHistory = []
                self.statusMessage = "Your account has been deleted."
            } catch {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    private func restoreSession() {
        guard APIClient.shared.hasStoredSession else { return }
        isRestoringSession = true
        Task {
            defer { self.isRestoringSession = false }
            do {
                self.applyMember(try await APIClient.shared.fetchCurrentMember())
            } catch {
                APIClient.shared.clearSession()
            }
        }
    }

    private func applyMember(_ member: Member) {
        currentMember = member
        announcementsEnabled = member.notificationsEnabled
        eventRemindersEnabled = member.eventRemindersEnabled
        discountAlertsEnabled = member.discountAlertsEnabled
        // Content is only needed after authentication. This keeps the login
        // screen instant and avoids competing with the sign-in request.
        loadData()
    }

    private func loadSavedItems() {
        func ids(_ key: String) -> Set<Int64> {
            Set((UserDefaults.standard.array(forKey: key) as? [NSNumber] ?? []).map(\.int64Value))
        }
        savedEventIDs = ids("saved_event_ids")
        savedDiscountIDs = ids("saved_discount_ids")
        savedServiceIDs = ids("saved_service_ids")
    }

    private func saveSavedItems() {
        UserDefaults.standard.set(Array(savedEventIDs), forKey: "saved_event_ids")
        UserDefaults.standard.set(Array(savedDiscountIDs), forKey: "saved_discount_ids")
        UserDefaults.standard.set(Array(savedServiceIDs), forKey: "saved_service_ids")
    }
}
