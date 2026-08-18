import SwiftUI

public struct DiscountsView: View {
    @EnvironmentObject var viewModel: BKKViewModel

    let categories = ["All", "Grocery", "Pharmacy", "Restaurant"]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            BkkTopBar(title: "Senior Savings & Deals")

            VStack(spacing: 14) {
                // Search Input Field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.bkkMuted)

                    TextField("Search discounts or stores...", text: $viewModel.searchText)
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
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                viewModel.selectedDiscountCategory = cat
                            }) {
                                Text(cat)
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedDiscountCategory == cat ? Color.bkkGold : Color.white)
                                    .foregroundColor(viewModel.selectedDiscountCategory == cat ? .white : .bkkInk)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(viewModel.selectedDiscountCategory == cat ? Color.bkkGold : Color.bkkLine, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Discounts List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.filteredDiscounts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tag.slash.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.bkkMuted)
                                Text("No discounts found")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.bkkNavy)
                                Text("Try searching for a different store or offer.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.bkkMuted)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.filteredDiscounts) { discount in
                                DiscountCard(
                                    discount: discount,
                                    isSaved: viewModel.savedDiscountIDs.contains(discount.id),
                                    onToggleSaved: {
                                        viewModel.toggleSavedDiscount(id: discount.id)
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
