import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var viewModel: BKKViewModel

    private var formattedTodayDate: String {
        BKKDateFormatting.today.string(from: Date())
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                BkkTopBar(title: "BKK Community")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What would you like to do today?")
                                .font(.title.bold())
                                .foregroundColor(.bkkNavy)

                            if let member = viewModel.currentMember {
                                Text("Hello, \(member.fullName.components(separatedBy: " ").first ?? member.fullName).")
                                    .font(.headline)
                                    .foregroundColor(.bkkNavy)
                            }

                            Text("Choose one option below. You can always return to Home.")
                                .font(.body)
                                .foregroundColor(.bkkMuted)

                            Text(formattedTodayDate)
                                .font(.subheadline)
                                .foregroundColor(.bkkMuted)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.bkkSky)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.bkkLine, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.top, 14)

                        // Demo Notice Banner (if offline / demo data)
                        if !viewModel.isConnectedToBackend {
                            DemoContentNotice()
                                .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("Choose one task")
                            Text("Each option takes you directly to what you need.")
                                .font(.body)
                                .foregroundColor(.bkkMuted)
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavigationLink(destination: EventsView()) {
                                ActionTile(title: "Events", subtitle: "Activities and gatherings", iconName: "calendar", color: .bkkBlue, surface: .bkkSky)
                            }
                            NavigationLink(destination: DiscountsView()) {
                                ActionTile(title: "Discounts", subtitle: "Find local savings", iconName: "tag.fill", color: .bkkGold, surface: .bkkGoldSurface)
                            }
                            NavigationLink(destination: ServicesView()) {
                                ActionTile(title: "Local services", subtitle: "Phone numbers and places", iconName: "cross.fill", color: .bkkTeal, surface: .bkkTealSurface)
                            }
                            Link(destination: URL(string: "https://wa.me/27728885030?text=Hello%20BKK%20Community%20Support%2C%20I%20need%20assistance.")!) {
                                ActionTile(title: "Contact BKK", subtitle: "Ask for help", iconName: "message.fill", color: .bkkGreen, surface: .bkkGreenSurface)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // Today's Schedule Section
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle("Today's Schedule")
                                .padding(.horizontal)

                            if viewModel.isLoading && viewModel.events.isEmpty {
                                ProgressView("Loading schedule...")
                                    .frame(maxWidth: .infinity, minHeight: 120)
                            } else if viewModel.upcomingEvents.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No events scheduled for today.")
                                        .font(.headline)
                                        .foregroundColor(.bkkNavy)
                                    Text("Check the Events tab for future dates.")
                                        .font(.body)
                                        .foregroundColor(.bkkMuted)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bkkSky)
                                .cornerRadius(20)
                                .padding(.horizontal)
                            } else {
                                ForEach(viewModel.upcomingEvents.prefix(1)) { event in
                                    EventCard(
                                        event: event,
                                        onAttendance: { _ in
                                            viewModel.toggleAttendance(eventID: event.id)
                                        },
                                        isSaved: viewModel.savedEventIDs.contains(event.id),
                                        onToggleSaved: {
                                            viewModel.toggleSavedEvent(id: event.id)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }

                        .padding(.bottom, 24)
                    }
                }
                .background(Color.bkkSurface.ignoresSafeArea())
            }
            .navigationBarHidden(true)
        }
    }
}
