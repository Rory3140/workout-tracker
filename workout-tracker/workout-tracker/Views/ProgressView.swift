import SwiftUI

struct ProgressView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Progress Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Progress")
        }
    }
}
