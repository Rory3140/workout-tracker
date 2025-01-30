import SwiftUI

struct WorkoutView: View {
    @State private var showWorkoutSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button(action: {
                    showWorkoutSheet.toggle()
                }) {
                    Text("Start Workout")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .navigationTitle("Workout")
            .sheet(isPresented: $showWorkoutSheet) {
                WorkoutBottomSheet(showWorkoutSheet: $showWorkoutSheet)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large, .medium], selection: .constant(.large))
            }
        }
    }
}

struct WorkoutBottomSheet: View {
    @Binding var showWorkoutSheet: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Button("Cancel Workout") {
                showWorkoutSheet = false
            }
            .padding()
        }
    }
}
