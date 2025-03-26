import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutViewModel.Workout
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Start: \(workout.startTime.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    
                    if let endTime = workout.endTime {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("End: \(endTime.formatted(date: .abbreviated, time: .shortened))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                // Description Card
                if !workout.description.isEmpty {
                    Text(workout.description)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Exercises Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Exercises")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ForEach(workout.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 10) {
                            if !exercise.name.isEmpty {
                                Text(exercise.name)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                            }
                            
                            ForEach(exercise.sets) { set in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .padding(.top, 4)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            if !set.weight.isEmpty {
                                                Text("Weight: \(userViewModel.convertWeightToDisplay(weight: set.weight)) \(exercise.weightUnit)")
                                                    .font(.subheadline)
                                            }
                                            
                                            Spacer()
                                            
                                            if !set.reps.isEmpty {
                                                Text("Reps: \(set.reps)")
                                                    .font(.subheadline)
                                            }
                                        }
                                        if !set.notes.isEmpty {
                                            Text((set.notes))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
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
