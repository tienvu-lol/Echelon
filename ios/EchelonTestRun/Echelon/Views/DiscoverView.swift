import SwiftUI

struct DiscoverView: View {
    @State private var recommendation: RecommendationItem?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Swipe on opportunities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 5)
                    
                    if isLoading {
                        ProgressView("Loading recommendations…")
                    } else if let errorMessage {
                        VStack(spacing: 12) {
                            Text("Unable to load recommendations")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await loadRecommendations() }
                            }
                        }
                        .padding()
                    } else if let recommendation {
                        recommendationCard(recommendation)
                    } else {
                        Text("No recommendations yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 400)
                .padding(.horizontal, 20)
                
                Spacer()
                
            }
            .navigationTitle("Discover")
            .task {
                await loadRecommendations()
            }
        }
    }

    private func recommendationCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.opportunity.title)
                .font(.title2.bold())
            Text(item.opportunity.organization)
                .font(.headline)

            HStack {
                Text(item.opportunity.opportunityType.capitalized)
                Spacer()
                Text("\(Int(item.score.rounded()))% match")
            }
            .font(.subheadline.weight(.semibold))

            if let location = item.opportunity.location {
                Text(location)
                    .foregroundColor(.secondary)
            }

            Text(item.matchReason)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let rawURL = item.opportunity.applyUrl,
               let url = URL(string: rawURL),
               ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
               url.host != nil {
                Link("Open Application", destination: url)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }

    @MainActor
    private func loadRecommendations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.getRecommendations(limit: 10)
            recommendation = response.opportunities.first
        } catch {
            recommendation = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    DiscoverView()
}

