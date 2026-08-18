import Foundation
import Security

private struct APIErrorEnvelope: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}

private enum APIClientError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case unauthenticated
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "The BKK server address is not configured correctly."
        case .invalidResponse:
            return "The server returned an invalid response. Please try again."
        case .unauthenticated:
            return "Please sign in to continue."
        case .server(let message):
            return message
        }
    }
}

private enum KeychainTokenStore {
    private static let service = "za.co.bkkcommunity.ios.auth"
    private static let account = "access-token"

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ token: String) throws {
        delete()
        guard let data = token.data(using: .utf8) else { throw APIClientError.invalidResponse }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data,
        ]
        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
            throw APIClientError.server("The secure session could not be saved.")
        }
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
public final class APIClient {
    public static let shared = APIClient()

    public let baseURLString: String
    private(set) var authToken: String?

    public var hasStoredSession: Bool { authToken != nil }

    private init() {
        let configuredURL = (Bundle.main.object(forInfoDictionaryKey: "BKK_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        baseURLString = configuredURL?.isEmpty == false
            ? configuredURL!
            : "https://api.bkkcommunity.invalid/api/v1"
        authToken = KeychainTokenStore.read()
    }

    private func url(_ path: String) throws -> URL {
        guard let url = URL(string: "\(baseURLString)\(path)"),
              url.scheme == "https" || url.host == "127.0.0.1" || url.host == "localhost" else {
            throw APIClientError.invalidConfiguration
        }
        return url
    }

    private func error(from data: Data, statusCode: Int) -> Error {
        let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data))?.error.message
            ?? "The server could not complete this request. Please try again."
        return NSError(domain: "BKKAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func execute(_ request: URLRequest, accepted: Set<Int> = [200]) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIClientError.invalidResponse }
        guard accepted.contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                clearSession()
            }
            throw error(from: data, statusCode: httpResponse.statusCode)
        }
        return data
    }

    private func request(
        _ path: String,
        method: String = "GET",
        body: [String: String]? = nil,
        authenticated: Bool = false
    ) throws -> URLRequest {
        var request = URLRequest(url: try url(path))
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        if authenticated {
            guard let authToken else { throw APIClientError.unauthenticated }
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    public func fetchEvents() async throws -> [CommunityEvent] {
        let data = try await execute(try request("/events"))
        return try JSONDecoder().decode(APIEnvelope<[CommunityEvent]>.self, from: data).data
    }

    public func fetchDiscounts() async throws -> [Discount] {
        let data = try await execute(try request("/discounts"))
        return try JSONDecoder().decode(APIEnvelope<[Discount]>.self, from: data).data
    }

    public func fetchServices() async throws -> [LocalService] {
        let data = try await execute(try request("/local-services"))
        return try JSONDecoder().decode(APIEnvelope<[LocalService]>.self, from: data).data
    }

    public func fetchCurrentMember() async throws -> Member {
        let data = try await execute(try request("/me", authenticated: true))
        return try JSONDecoder().decode(APIEnvelope<Member>.self, from: data).data
    }

    public func fetchAttendanceHistory() async throws -> [CommunityEvent] {
        let data = try await execute(try request("/me/attendance", authenticated: true))
        return try JSONDecoder().decode(APIEnvelope<[CommunityEvent]>.self, from: data).data
    }

    public func register(name: String, email: String, phone: String?, password: String) async throws -> Member {
        var body = ["full_name": name, "email": email, "password": password]
        if let phone, !phone.isEmpty { body["phone"] = phone }
        let data = try await execute(
            try request("/auth/register", method: "POST", body: body),
            accepted: [200, 201]
        )
        let session = try JSONDecoder().decode(APIEnvelope<AuthSession>.self, from: data).data
        try KeychainTokenStore.save(session.token)
        authToken = session.token
        return session.user
    }

    public func login(email: String, password: String) async throws -> Member {
        let data = try await execute(try request(
            "/auth/login",
            method: "POST",
            body: ["email": email, "password": password]
        ))
        let session = try JSONDecoder().decode(APIEnvelope<AuthSession>.self, from: data).data
        try KeychainTokenStore.save(session.token)
        authToken = session.token
        return session.user
    }

    public func logout() {
        // Capture the authenticated request first, then remove the local token
        // immediately. Server revocation is best-effort and must never delay or
        // undo a local sign-out.
        let revocationRequest = try? request("/auth/session", method: "DELETE", authenticated: true)
        clearSession()
        guard let revocationRequest else { return }
        Task { _ = try? await execute(revocationRequest) }
    }

    public func clearSession() {
        authToken = nil
        KeychainTokenStore.delete()
    }

    public func toggleAttendance(eventID: Int64, isAttending: Bool) async throws {
        _ = try await execute(try request(
            "/events/\(eventID)/attendance",
            method: "PUT",
            body: ["status": isAttending ? "attending" : "cancelled"],
            authenticated: true
        ))
    }

    public func updateNotificationPreferences(
        notifications: Bool,
        eventReminders: Bool,
        discountAlerts: Bool
    ) async throws -> Member {
        var request = try request("/me/notification-preferences", method: "PATCH", authenticated: true)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "notifications_enabled": notifications,
            "event_reminders_enabled": eventReminders,
            "discount_alerts_enabled": discountAlerts,
        ])
        let data = try await execute(request)
        return try JSONDecoder().decode(APIEnvelope<Member>.self, from: data).data
    }

    public func updateProfile(name: String, email: String, phone: String?) async throws -> Member {
        var body = ["full_name": name, "email": email]
        if let phone { body["phone"] = phone }
        let data = try await execute(try request(
            "/me",
            method: "PATCH",
            body: body,
            authenticated: true
        ))
        return try JSONDecoder().decode(APIEnvelope<Member>.self, from: data).data
    }

    public func submitContact(name: String, email: String, message: String) async throws {
        _ = try await execute(
            try request(
                "/contact",
                method: "POST",
                body: ["name": name, "email": email, "message": message]
            ),
            accepted: [200, 201]
        )
    }

    public func deleteAccount() async throws {
        _ = try await execute(try request("/me", method: "DELETE", authenticated: true))
        clearSession()
    }

    public func requestPasswordReset(email: String) async throws {
        _ = try await execute(try request(
            "/auth/forgot-password",
            method: "POST",
            body: ["email": email]
        ))
    }

    public func submitPasswordReset(email: String, token: String, newPassword: String) async throws {
        _ = try await execute(try request(
            "/auth/reset-password",
            method: "POST",
            body: ["email": email, "token": token, "password": newPassword]
        ))
        clearSession()
    }
}
