import SwiftUI

struct WorkoutLogsView: View {
    @StateObject var workoutViewModel = WorkoutViewModel()
    @StateObject var userViewModel = UserViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(workoutViewModel.userWorkouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout, userViewModel: userViewModel)) {
                            VStack(alignment: .leading) {
                                Text(workout.name)
                                    .font(.headline)
                                
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
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
                .navigationTitle("Workout Logs")
                .onAppear {
                    workoutViewModel.fetchUserWorkouts()
                }
            }
        }
    }
    
    /// Handles deletion of a workout
    private func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workout = workoutViewModel.userWorkouts[index]
            workoutViewModel.deleteWorkout(workoutId: workout.id)
        }
    }
}
