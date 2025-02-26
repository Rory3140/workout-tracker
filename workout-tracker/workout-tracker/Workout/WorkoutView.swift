import SwiftUI

struct WorkoutView: View {
    @Binding var showWorkoutSheet: Bool
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Spacer()
                    Button(action: {
                        showWorkoutSheet.toggle()
                    }) {                        Text((workoutViewModel.workoutName.isEmpty &&
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
                    .padding(.bottom, 20)
                }
                .navigationTitle("Workout")
            }
        }
    }
}
