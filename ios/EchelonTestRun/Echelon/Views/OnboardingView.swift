import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("🎯")
                .font(.system(size: 80))
            
            VStack(spacing: 8) {
                Text("Echelon")
                    .font(.system(size: 40, weight: .bold))
                
                Text("Discover campus opportunities\ntailored just for you")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "doc.text.fill", text: "Upload your resume")
                FeatureRow(icon: "sparkles", text: "AI-powered matching")
                FeatureRow(icon: "hand.draw.fill", text: "Swipe to discover")
                FeatureRow(icon: "pin.fill", text: "Save what matters")
            }
            .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    appState.hasCompletedOnboarding = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.52, green: 0.12, blue: 0.25)) // VT Maroon
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(red: 0.90, green: 0.45, blue: 0.15)) // VT Burnt Orange
                .frame(width: 30)
            
            Text(text)
                .font(.title3)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}

