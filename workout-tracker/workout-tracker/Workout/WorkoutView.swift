import SwiftUI

struct WorkoutView: View {
    @State private var showWorkoutSheet = false
    @StateObject private var workoutViewModel = WorkoutViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Button(action: {
                        showWorkoutSheet.toggle()
                    }) {
                        // If no workout data has been entered, show "Start Workout"; otherwise, "Resume Workout"
                        Text((workoutViewModel.workoutName.isEmpty &&
                              workoutViewModel.workoutDescription.isEmpty &&
                              workoutViewModel.exercises.isEmpty) ? "Start Workout" : "Resume Workout")
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
                    WorkoutBottomSheet(showWorkoutSheet: $showWorkoutSheet, workoutViewModel: workoutViewModel)
                }
            }
        }
    }
}
