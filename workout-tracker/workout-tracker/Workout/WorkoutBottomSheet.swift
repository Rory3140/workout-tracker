import SwiftUI

struct WorkoutBottomSheet: View {
    @Binding var showWorkoutSheet: Bool
    @ObservedObject var workoutViewModel: WorkoutViewModel  // Received from parent
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showCancelAlert = false
    @State private var showFinishAlert = false
    @State private var showDeleteAlert = false
    @State private var exerciseToDeleteIndex: Int?
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                
                // Top bar with Finish button
                HStack {
                    Button(action: {
                        showCancelAlert = true
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showFinishAlert = true
                    }) {
                        Text("Finish")
                            .foregroundColor(.green)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                .padding(16)
                
                List {
                    Section {
                        TextField("Workout Name", text: $workoutViewModel.workoutName)
                            .keyboardType(.default)
                            .focused($isInputActive)
                        
                        DatePicker("Start Time", selection: $workoutViewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        if let endTime = workoutViewModel.endTime {
                            DatePicker("End Time", selection: Binding(
                                get: { endTime },
                                set: { workoutViewModel.endTime = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        } else {
                            Text("End Time: ")
                                .foregroundColor(.gray)
                        }
                        
                        TextField("Workout Description", text: $workoutViewModel.workoutDescription)
                            .keyboardType(.default)
                            .focused($isInputActive)
                    }
                    
                    ForEach(workoutViewModel.exercises.indices, id: \.self) { index in
                        Section {
                            TextField("Exercise Name", text: $workoutViewModel.exercises[index].name)
                                .keyboardType(.default)
                                .focused($isInputActive)
                            
                            ForEach(workoutViewModel.exercises[index].sets.indices, id: \.self) { setIndex in
                                HStack {
                                    Text("Set \(setIndex + 1)")
                                        .font(.subheadline)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Weight", text: $workoutViewModel.exercises[index].sets[setIndex].weight)
                                        .keyboardType(.decimalPad)
                                        .focused($isInputActive)
                                        .frame(width: 60)
                                    
                                    Text(userViewModel.selectedWeightUnit)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Reps", text: $workoutViewModel.exercises[index].sets[setIndex].reps)
                                        .keyboardType(.numberPad)
                                        .focused($isInputActive)
                                        .frame(width: 100)
                                    
                                }
                                .padding(.horizontal)
                            }
                            .onDelete { indexSet in
                                workoutViewModel.exercises[index].sets.remove(atOffsets: indexSet)
                            }
                            
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        workoutViewModel.exercises[index].sets.append(WorkoutViewModel.Set(weight: "", reps: ""))
                                    }
                                }) {
                                    Text("Add Set")
                                        .foregroundColor(.blue)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.borderless)
                                .padding(.leading, 16)
                                
                                Spacer()
                                
                                Menu {
                                    Button(role: .destructive) {
                                        exerciseToDeleteIndex = index
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete Exercise", systemImage: "trash")
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
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                workoutViewModel.exercises.append(WorkoutViewModel.Exercise(name: "", sets: [WorkoutViewModel.Set(weight: "", reps: "")]))
                            }
                        }) {
                            Text("Add Exercise")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                }
                .padding(.vertical, 0)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
            }
        }
        
        // Cancel Workout Confirmation
        .alert("Are you sure you want to cancel the workout?", isPresented: $showCancelAlert) {
            Button("Yes", role: .destructive) {
                showWorkoutSheet = false
            }
            Button("No", role: .cancel) { }
        }
        
        // Finish Workout Confirmation
        .alert("Are you sure you want to finish?", isPresented: $showFinishAlert) {
            Button("Yes", role: .destructive) {
                workoutViewModel.endTime = Date()
                workoutViewModel.saveWorkout()
                showWorkoutSheet = false
            }.foregroundColor(Color.blue)
            
            Button("No", role: .cancel) { }
            .foregroundColor(Color.red)
        }
        
        // Delete Exercise Confirmation
        .alert("Are you sure you want to delete this exercise?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                if let index = exerciseToDeleteIndex {
                    workoutViewModel.exercises.remove(at: index)
                }
            }
            Button("No", role: .cancel) { }
        }
    }
}
