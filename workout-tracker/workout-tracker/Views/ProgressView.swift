import SwiftUI

struct ProgressView: View {
    
    @FocusState var isInputActive: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Progress Tab")
                        .font(.title)
                        .padding()

                }
                .navigationTitle("Progress")
            }
        }
    }
}
