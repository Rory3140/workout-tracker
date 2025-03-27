import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Binding var showSummary: Bool
    var onContinue: () -> Void
    var onReturn: () -> Void
    
    @State private var animateCelebration = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated celebration icon.
            Text("🎉")
                .font(.system(size: 100))
                .scaleEffect(animateCelebration ? 1.2 : 0.8)
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateCelebration)
                .onAppear {
                    animateCelebration = true
                }
            
            Text("Great job!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.green)
            
            // Workout summary details.
            VStack(alignment: .leading, spacing: 10) {
                Text(workoutViewModel.workoutName)
                    .font(.headline)
                if let duration = workoutViewModel.endTime.map({
                    Calendar.current.dateComponents([.minute], from: workoutViewModel.startTime, to: $0).minute ?? 0
                }) {
                    Text("Duration: \(duration) min")
                        .font(.subheadline)
                }
                Text("Exercises: \(workoutViewModel.exercises.count)")
                    .font(.subheadline)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)
            
            Spacer()
            
            // Action Buttons.
            VStack(spacing: 15) {
                Button(action: {
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    onReturn()
                }) {
                    Text("Return to Workout")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
