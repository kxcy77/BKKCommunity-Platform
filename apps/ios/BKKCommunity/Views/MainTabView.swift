import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = BKKViewModel()

    public var body: some View {
        Group {
            if viewModel.isRestoringSession {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Checking your secure session…")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.bkkSurface.ignoresSafeArea())
                .accessibilityElement(children: .combine)
            } else if viewModel.currentMember == nil {
                AccountView(requiresAuthentication: true)
                    // Keep the mandatory authentication screen separate from the
                    // Account tab's optional sign-in state. This guarantees fresh
                    // presentation state after a member signs out.
                    .id("mandatory-authentication")
            } else {
                platformTabs
            }
        }
        .environmentObject(viewModel)
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.statusMessage.map { AlertItem(message: $0) } },
            set: { _ in viewModel.statusMessage = nil }
        )) { alertItem in
            Alert(title: Text("BKK Community"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }

    private var platformTabs: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            DiscountsView()
                .tabItem {
                    Label("Discounts", systemImage: "tag.fill")
                }

            ServicesView()
                .tabItem {
                    Label("Services", systemImage: "info.circle.fill")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
            }
        .accentColor(Color(hex: "#315C24"))
    }
}

public struct AlertItem: Identifiable {
    public let id = UUID()
    public let message: String
}
