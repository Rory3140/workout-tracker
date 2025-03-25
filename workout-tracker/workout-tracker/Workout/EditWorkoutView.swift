import SwiftUI

struct EditWorkoutView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Environment(\.presentationMode) var presentationMode

    // Local copy of the workout for editing.
    @State var editedWorkout: WorkoutViewModel.Workout

    // Initialize with the original workout.
    init(originalWorkout: WorkoutViewModel.Workout) {
        _editedWorkout = State(initialValue: originalWorkout)
    }

    var body: some View {
        NavigationView {
            Form {
                // Basic workout details.
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $editedWorkout.name)
                    TextField("Description", text: $editedWorkout.description)
                }
                
                // Timing details.
                Section(header: Text("Workout Timing")) {
                    DatePicker("Start Time", selection: $editedWorkout.startTime, displayedComponents: [.date, .hourAndMinute])
                    if let _ = editedWorkout.endTime {
                        DatePicker("End Time", selection: Binding(
                            get: { editedWorkout.endTime ?? Date() },
                            set: { editedWorkout.endTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    } else {
                        Button("Add End Time") {
                            editedWorkout.endTime = Date()
                        }
                    }
                }
                
                // For each exercise, create its own Section.
                ForEach(editedWorkout.exercises.indices, id: \.self) { index in
                    Section() {
                        TextField("Exercise Name", text: $editedWorkout.exercises[index].name)
                        
                        // For each set, use a ForEach with onDelete.
                        ForEach(editedWorkout.exercises[index].sets.indices, id: \.self) { setIndex in
                            HStack {
                                Text("Set \(setIndex + 1)")
                                    .frame(width: 50, alignment: .leading)
                                Spacer()
                                // Weight input with label above.
                                VStack(spacing: 2) {
                                    Text(editedWorkout.exercises[index].weightUnit)
                                        .font(.caption)
                                    TextField("0", text: $editedWorkout.exercises[index].sets[setIndex].weight)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                }
                                Spacer()
                                // Reps input with label above.
                                VStack(spacing: 2) {
                                    Text("Reps")
                                        .font(.caption)
                                    TextField("0", text: $editedWorkout.exercises[index].sets[setIndex].reps)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                }
                                Spacer()
                                // Notes field.
                                TextField("Notes", text: $editedWorkout.exercises[index].sets[setIndex].notes)
                                    .keyboardType(.default)
                            }
                        }
                        .onDelete { indexSet in
                            editedWorkout.exercises[index].sets.remove(atOffsets: indexSet)
                        }
                        
                        // Row with Add Set and context menu.
                        HStack {
                            Button(action: {
                                editedWorkout.exercises[index].sets.append(WorkoutViewModel.Set(weight: "", reps: ""))
                            }) {
                                Text("Add Set")
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Spacer()
                            Menu {
                                Button(role: .destructive) {
                                    editedWorkout.exercises.remove(at: index)
                                } label: {
                                    Label("Delete Exercise", systemImage: "trash")
                                }
                                Button {
                                    let currentUnit = editedWorkout.exercises[index].weightUnit
                                    editedWorkout.exercises[index].weightUnit = (currentUnit == "kg" ? "lbs" : "kg")
                                } label: {
                                    Label("Switch to \(editedWorkout.exercises[index].weightUnit == "kg" ? "lbs" : "kg")", systemImage: "arrow.2.circlepath")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                }
                
                // Button to add a new exercise.
                Section {
                    Button(action: {
                        editedWorkout.exercises.append(
                            WorkoutViewModel.Exercise(
                                name: "",
                                sets: [WorkoutViewModel.Set(weight: "", reps: "")],
                                weightUnit: userViewModel.selectedWeightUnit
                            )
                        )
                    }) {
                        Text("Add Exercise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Edit Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        workoutViewModel.updateWorkout(editedWorkout)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
