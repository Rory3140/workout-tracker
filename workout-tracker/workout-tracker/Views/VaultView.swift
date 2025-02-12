import SwiftUI

struct VaultView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Exercise Valut Tab")
                        .font(.title)
                        .padding()
                }
                .navigationTitle("Exercise Valut")
            }
        }
    }
}
