import SwiftUI

struct WorkoutView: View {
    @Binding var showWorkoutSheet: Bool
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient for a modern look.
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Header card with icon and title.
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        Text("LiftSync")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    
                    Spacer()
                    
                    // Start/Resume button styled as a full-width card.
                    Button(action: {
                        showWorkoutSheet.toggle()
                    }) {
                        Text((workoutViewModel.workoutName.isEmpty &&
                              workoutViewModel.workoutDescription.isEmpty &&
                              workoutViewModel.exercises.isEmpty) ? "Start Workout" : "Resume Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitle("Workout", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
}
