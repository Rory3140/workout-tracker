import SwiftUI

struct VaultView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Exercise Valut Tab")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Exercise Valut")
        }
    }
}
