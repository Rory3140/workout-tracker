import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutViewModel.Workout
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var showEditSheet = false

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
                
                if !workout.description.isEmpty {
                    Text(workout.description)
                        .font(.body)
                        .padding(.vertical, 5)
                }
                
                Divider()
                
                Text("Exercises")
                    .font(.title2)
                    .bold()
                
                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 5) {
                        if !exercise.name.isEmpty {
                            Text(exercise.name)
                                .font(.headline)
                        }
                        
                        ForEach(exercise.sets) { set in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if !set.weight.isEmpty {
                                        // Use the exercise's weightUnit property here.
                                        Text("Weight: \(userViewModel.convertWeightToDisplay(weight: set.weight)) \(exercise.weightUnit)")
                                    }
                                    if !set.reps.isEmpty {
                                        if !set.weight.isEmpty { Spacer() }
                                        Text("Reps: \(set.reps)")
                                    }
                                }
                                if !set.notes.isEmpty {
                                    Text("Notes: \(set.notes)")
                                }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditWorkoutView(originalWorkout: workout)
                .environmentObject(userViewModel)
                .environmentObject(workoutViewModel)
        }
    }
}
