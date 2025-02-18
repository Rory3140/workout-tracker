import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutViewModel.Workout
    @ObservedObject var userViewModel: UserViewModel
    
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
                            let convertedWeight = userViewModel.convertWeightToDisplay(weight: set.weight)
                            let weightUnit = userViewModel.selectedWeightUnit
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if !set.weight.isEmpty {
                                        Text("Weight: \(convertedWeight) \(weightUnit)")
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
    }
}
