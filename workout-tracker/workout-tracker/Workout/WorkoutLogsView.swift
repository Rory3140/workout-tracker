import SwiftUI

typealias Workout = WorkoutViewModel.Workout

struct WorkoutLogsView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    // Group workouts by month/year.
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
                result.append((key: key, workouts: workouts, date: date))
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
                
                // Using a local constant to help the type-checker.
                let sections = groupedWorkouts
                
                List {
                    ForEach(sections, id: \.key) { group in
                        Section(header: sectionHeader(for: group)) {
                            ForEach(group.workouts) { workout in
                                WorkoutRow(workout: workout, userViewModel: userViewModel)
                            }
                            .onDelete { offsets in
                                deleteWorkout(in: group.workouts, at: offsets)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Workout Logs")
            }
        }
    }
    
    // A helper function to build the section header.
    private func sectionHeader(for group: (key: String, workouts: [Workout], date: Date)) -> some View {
        Text("\(group.key) - \(group.workouts.count) Workouts")
            .font(.headline)
    }
    
    // A helper function to delete workouts.
    private func deleteWorkout(in workouts: [Workout], at offsets: IndexSet) {
        for index in offsets {
            let workout = workouts[index]
            workoutViewModel.deleteWorkout(workoutId: workout.id)
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    let userViewModel: UserViewModel
    // Get the instance of WorkoutViewModel from the environment.
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    
    var body: some View {
        NavigationLink(
            destination: WorkoutDetailView(
                workout: workout,
                userViewModel: userViewModel,
                workoutViewModel: workoutViewModel  // Use the instance, not the type.
            )
        ) {
            HStack {
                // Left Column: Day of week above day number.
                VStack {
                    Text(workout.startTime, format: Date.FormatStyle().weekday(.abbreviated))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text(workout.startTime, format: Date.FormatStyle().day())
                        .font(.headline)
                }
                .frame(width: 50)
                
                // Middle Column: Workout name and creator.
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                    if !workout.createdBy.isEmpty {
                        UserDisplayName(userViewModel: userViewModel, userId: workout.createdBy)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Right Column: Duration.
                if let duration = workout.duration {
                    Text("\(duration) min")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct UserDisplayName: View {
    @ObservedObject var userViewModel: UserViewModel
    let userId: String
    @State private var displayName: String = ""
    
    var body: some View {
        Text("@" + (displayName.isEmpty ? "" : displayName))
            .font(.footnote)
            .foregroundColor(.gray)
            .onAppear {
                userViewModel.getDisplayName(for: userId) { name in
                    displayName = name
                }
            }
    }
}
