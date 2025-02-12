import SwiftUI

struct WorkoutView: View {
    @State private var showWorkoutSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
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
                }
            }
        }
    }
}
