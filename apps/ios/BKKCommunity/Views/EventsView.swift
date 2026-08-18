import SwiftUI

public struct EventsView: View {
    @EnvironmentObject var viewModel: BKKViewModel
    let categories = ["All", "Exercise", "Social", "Health"]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            BkkTopBar(title: "Community Events")

            VStack(spacing: 14) {
                // Search Input Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.bkkMuted)

                    TextField("Search events by title or location...", text: $viewModel.searchText)
                        .font(.system(size: 16))

                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.bkkMuted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bkkLine, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 14)

                // Category Chips & Free Filter Toggle
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                viewModel.selectedEventCategory = cat
                            }) {
                                Text(cat)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedEventCategory == cat ? Color.bkkBlue : Color.white)
                                    .foregroundColor(viewModel.selectedEventCategory == cat ? .white : .bkkInk)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(viewModel.selectedEventCategory == cat ? Color.bkkBlue : Color.bkkLine, lineWidth: 1)
                                    )
                            }
                        }

                        Button(action: {
                            viewModel.isFreeOnly.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isFreeOnly ? "checkmark.circle.fill" : "circle")
                                Text("Free Only")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(viewModel.isFreeOnly ? Color.bkkGreenSurface : Color.white)
                            .foregroundColor(viewModel.isFreeOnly ? Color.bkkGreen : .bkkInk)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(viewModel.isFreeOnly ? Color.bkkGreen : Color.bkkLine, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Events List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.filteredEvents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 44))
                                    .foregroundColor(.bkkMuted)
                                Text("No matching events found")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.bkkNavy)
                                Text("Try clearing your search or category filter.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.bkkMuted)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.filteredEvents) { event in
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
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
            .background(Color.bkkSurface.ignoresSafeArea())
        }
        .navigationBarHidden(true)
    }
}
