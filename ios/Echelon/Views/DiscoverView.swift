import SwiftUI

struct DiscoverView: View {
    @State private var backendStatus: String = "checking..."
    
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
                    
                    VStack {
                        Text("Opportunity cards will appear here")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Swipe right to save, left to skip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 400)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text(backendStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom)
            }
            .navigationTitle("Discover")
            .onAppear {
                checkBackendHealth()
            }
        }
    }
    
    private func checkBackendHealth() {
        Task {
            do {
                let response = try await APIService.shared.healthCheck()
                await MainActor.run {
                    backendStatus = "Backend: \(response.status)"
                }
            } catch {
                await MainActor.run {
                    backendStatus = "Backend: offline (\(error.localizedDescription))"
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}

