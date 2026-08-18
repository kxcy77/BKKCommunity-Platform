import SwiftUI

public struct ServicesView: View {
    @EnvironmentObject var viewModel: BKKViewModel

    let serviceTypes = ["All", "Clinic", "Pharmacy", "Support", "Transport"]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            BkkTopBar(title: "Local Info & Services")

            VStack(spacing: 14) {
                // Search Input Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.bkkMuted)

                    TextField("Search services or addresses...", text: $viewModel.searchText)
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

                // Category Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(serviceTypes, id: \.self) { type in
                            Button(action: {
                                viewModel.selectedServiceType = type
                            }) {
                                Text(type)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedServiceType == type ? Color.bkkTeal : Color.white)
                                    .foregroundColor(viewModel.selectedServiceType == type ? .white : .bkkInk)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(viewModel.selectedServiceType == type ? Color.bkkTeal : Color.bkkLine, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Services List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.filteredServices.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.bkkMuted)
                                Text("No local services found")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.bkkNavy)
                                Text("Try searching for a clinic, pharmacy, or support desk.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.bkkMuted)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.filteredServices) { service in
                                ServiceCard(
                                    service: service,
                                    isSaved: viewModel.savedServiceIDs.contains(service.id),
                                    onToggleSaved: {
                                        viewModel.toggleSavedService(id: service.id)
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
