import SwiftUI

struct SavedView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "pin.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .padding(.bottom, 10)
                
                Text("No saved opportunities yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Swipe right on opportunities in Discover to save them here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                
                Spacer()
            }
            .navigationTitle("Saved")
        }
    }
}

#Preview {
    SavedView()
}

