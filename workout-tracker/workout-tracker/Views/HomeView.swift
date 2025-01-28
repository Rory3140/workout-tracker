import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Home Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Home")
        }
    }
}
