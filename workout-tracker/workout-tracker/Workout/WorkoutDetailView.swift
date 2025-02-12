import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutViewModel.Workout
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                
                Text("Start: \(workout.startTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let endTime = workout.endTime {
                    Text("End: \(endTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text(workout.description)
                    .font(.body)
                    .padding(.vertical, 5)
                
                Divider()
                
                Text("Exercises")
                    .font(.title2)
                    .bold()
                
                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        ForEach(exercise.sets) { set in
                            HStack {
                                Text("Weight: \(set.weight) lbs")
                                Spacer()
                                Text("Reps: \(set.reps)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
        }
        .navigationTitle(workout.name)
    }
}
