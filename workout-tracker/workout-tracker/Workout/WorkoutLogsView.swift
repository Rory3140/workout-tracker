import SwiftUI

typealias Workout = WorkoutViewModel.Workout

struct WorkoutLogsView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    /// Groups workouts by month/year and sorts them by date descending.
    private var groupedWorkouts: [(key: String, workouts: [Workout], date: Date)] {
        let grouped = Dictionary(grouping: workoutViewModel.userWorkouts) { workout -> DateComponents in
            Calendar.current.dateComponents([.year, .month], from: workout.startTime)
        }
        var result: [(key: String, workouts: [Workout], date: Date)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g. "January 2025"
        for (components, workouts) in grouped {
            if let date = Calendar.current.date(from: components) {
                let key = formatter.string(from: date)
                result.append((key, workouts, date))
            }
        }
        result.sort { $0.date > $1.date }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(groupedWorkouts, id: \.key) { group in
                        Section(header: Text("\(group.key) - \(group.workouts.count) Workouts")
                                    .font(.headline)) {
                            ForEach(group.workouts) { workout in
                                NavigationLink(
                                    destination: WorkoutDetailView(workout: workout, userViewModel: userViewModel)
                                ) {
                                    HStack {
                                        // Left Column: Day of week above day number
                                        VStack {
                                            Text(workout.startTime, format: Date.FormatStyle().weekday(.abbreviated))
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                            Text(workout.startTime, format: Date.FormatStyle().day())
                                                .font(.headline)
                                        }
                                        .frame(width: 50)
                                        
                                        // Middle Column: Workout name above creator handle
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.name)
                                                .font(.headline)
                                            if !workout.createdBy.isEmpty {
                                                Text("@\(workout.createdBy)")
                                                    .font(.footnote)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(.leading, 8)
                                        
                                        Spacer()
                                        
                                        // Right Column: Duration (if available)
                                        if let duration = workout.duration {
                                            Text("\(duration) min")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete { offsets in
                                deleteWorkout(in: group.workouts, at: offsets)
                            }
                        }
                    }
                }
                .navigationTitle("Workout Logs")
                .onAppear {
                    // Only fetch if not already loaded.
                    if workoutViewModel.userWorkouts.isEmpty {
                        workoutViewModel.fetchUserWorkouts()
                    }
                }
            }
        }
    }
    
    /// Deletes the selected workout(s) from a given group.
    private func deleteWorkout(in workouts: [Workout], at offsets: IndexSet) {
        for index in offsets {
            let workout = workouts[index]
            workoutViewModel.deleteWorkout(workoutId: workout.id)
        }
    }
}
