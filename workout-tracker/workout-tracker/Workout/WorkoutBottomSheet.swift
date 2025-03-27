import SwiftUI

struct WorkoutBottomSheet: View {
    @Binding var showWorkoutSheet: Bool
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showCancelAlert = false
    @State private var showDeleteAlert = false
    @State private var exerciseToDeleteIndex: Int?
    @State private var showSummaryView = false  // New state for summary presentation
    
    // Define focusable fields.
    enum Field: Hashable {
        case workoutName
        case workoutDescription
        case exerciseName(Int)
        case setWeight(exercise: Int, set: Int)
        case setReps(exercise: Int, set: Int)
        case setNotes(exercise: Int, set: Int)
    }
    
    // Currently focused field.
    @FocusState private var focusedField: Field?
    
    // Returns an ordered list of all focusable fields.
    private func getFocusableFields() -> [Field] {
        var fields: [Field] = []
        fields.append(.workoutName)
        fields.append(.workoutDescription)
        for exerciseIndex in workoutViewModel.exercises.indices {
            fields.append(.exerciseName(exerciseIndex))
            for setIndex in workoutViewModel.exercises[exerciseIndex].sets.indices {
                fields.append(.setWeight(exercise: exerciseIndex, set: setIndex))
                fields.append(.setReps(exercise: exerciseIndex, set: setIndex))
                fields.append(.setNotes(exercise: exerciseIndex, set: setIndex))
            }
        }
        return fields
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top bar with Cancel and Finish buttons.
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
                        // If no title was provided, generate a default workout name so it shows in the summary.
                        if workoutViewModel.workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            workoutViewModel.workoutName = workoutViewModel.defaultWorkoutName(from: workoutViewModel.startTime)
                        }
                        // Instead of showing an alert, present the summary view.
                        showSummaryView = true
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
                
                ScrollViewReader { scrollProxy in
                    List {
                        Section {
                            TextField("Workout Name", text: $workoutViewModel.workoutName)
                                .keyboardType(.default)
                                .focused($focusedField, equals: .workoutName)
                                .id(Field.workoutName)
                            
                            DatePicker("Start Time", selection: $workoutViewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            TextField("Workout Description", text: $workoutViewModel.workoutDescription)
                                .keyboardType(.default)
                                .focused($focusedField, equals: .workoutDescription)
                                .id(Field.workoutDescription)
                        }
                        
                        ForEach(workoutViewModel.exercises.indices, id: \.self) { index in
                            Section {
                                TextField("Exercise Name", text: $workoutViewModel.exercises[index].name)
                                    .keyboardType(.default)
                                    .focused($focusedField, equals: .exerciseName(index))
                                    .id(Field.exerciseName(index))
                                
                                ForEach(workoutViewModel.exercises[index].sets.indices, id: \.self) { setIndex in
                                    HStack {
                                        Text("Set \(setIndex + 1)")
                                            .font(.subheadline)
                                            .frame(width: 40, alignment: .leading)
                                        
                                        VStack(spacing: 2) {
                                            Text(workoutViewModel.exercises[index].weightUnit)
                                                .font(.caption)
                                            TextField("0", text: $workoutViewModel.exercises[index].sets[setIndex].weight)
                                                .keyboardType(.decimalPad)
                                                .frame(width: 40)
                                                .multilineTextAlignment(.center)
                                                .focused($focusedField, equals: .setWeight(exercise: index, set: setIndex))
                                                .id(Field.setWeight(exercise: index, set: setIndex))
                                        }
                                        
                                        VStack(spacing: 2) {
                                            Text("Reps")
                                                .font(.caption)
                                            TextField("0", text: $workoutViewModel.exercises[index].sets[setIndex].reps)
                                                .keyboardType(.numberPad)
                                                .frame(width: 40)
                                                .multilineTextAlignment(.center)
                                                .focused($focusedField, equals: .setReps(exercise: index, set: setIndex))
                                                .id(Field.setReps(exercise: index, set: setIndex))
                                        }
                                        
                                        TextField("Notes", text: $workoutViewModel.exercises[index].sets[setIndex].notes)
                                            .keyboardType(.default)
                                            .focused($focusedField, equals: .setNotes(exercise: index, set: setIndex))
                                            .id(Field.setNotes(exercise: index, set: setIndex))
                                            .padding(.leading, 8)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                                }
                                .onDelete { indexSet in
                                    workoutViewModel.exercises[index].sets.remove(atOffsets: indexSet)
                                }
                                
                                HStack {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            workoutViewModel.exercises[index].sets.append(
                                                WorkoutViewModel.Set(weight: "", reps: "")
                                            )
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
                                        
                                        Button {
                                            let currentUnit = workoutViewModel.exercises[index].weightUnit
                                            let newUnit = currentUnit == "kg" ? "lbs" : "kg"
                                            workoutViewModel.exercises[index].weightUnit = newUnit
                                        } label: {
                                            Label("Switch to \(workoutViewModel.exercises[index].weightUnit == "kg" ? "lbs" : "kg")", systemImage: "arrow.2.circlepath")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24))
                                            .frame(width: 44, height: 44)
                                    }
                                }
                            }
                            .id("exercise\(index)")
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    workoutViewModel.exercises.append(
                                        WorkoutViewModel.Exercise(
                                            name: "",
                                            sets: [WorkoutViewModel.Set(weight: "", reps: "")],
                                            weightUnit: userViewModel.selectedWeightUnit
                                        )
                                    )
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
                        .id("bottom")
                    }
                    .onChange(of: workoutViewModel.exercises.count) { newCount, oldCount in
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: focusedField) { newField, oldField in
                        guard let newField = newField else { return }
                        
                        let anchor: UnitPoint = {
                            switch newField {
                            case .setWeight(_, _), .setReps(_, _), .setNotes(_, _):
                                return .bottom
                            default:
                                return .center
                            }
                        }()
                        
                        let newIsNumeric: Bool = {
                            switch newField {
                            case .setWeight(_, _), .setReps(_, _):
                                return true
                            default:
                                return false
                            }
                        }()
                        
                        let oldIsNumeric: Bool = {
                            if let old = oldField {
                                switch old {
                                case .setWeight(_, _), .setReps(_, _):
                                    return true
                                default:
                                    return false
                                }
                            }
                            return false
                        }()
                        
                        let delay = (newIsNumeric && !oldIsNumeric) ? 0.3 : 0.0
                        
                        if delay > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation {
                                    scrollProxy.scrollTo(newField, anchor: anchor)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                withAnimation {
                                    scrollProxy.scrollTo(newField, anchor: anchor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if workoutViewModel.workoutName.isEmpty && workoutViewModel.exercises.isEmpty {
                workoutViewModel.startTime = Date()
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(action: {
                    let fields = getFocusableFields()
                    if let current = focusedField,
                       let currentIndex = fields.firstIndex(of: current),
                       currentIndex > 0 {
                        focusedField = fields[currentIndex - 1]
                    } else {
                        focusedField = fields.last
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Button(action: {
                    let fields = getFocusableFields()
                    if let current = focusedField,
                       let currentIndex = fields.firstIndex(of: current),
                       currentIndex < fields.count - 1 {
                        focusedField = fields[currentIndex + 1]
                    } else {
                        focusedField = fields.first
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
                Spacer()
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
        .alert("Are you sure you want to cancel the workout?", isPresented: $showCancelAlert) {
            Button("Yes", role: .destructive) {
                workoutViewModel.resetWorkout()
                showWorkoutSheet = false
            }
            Button("No", role: .cancel) { }
        }
        .alert("Are you sure you want to delete this exercise?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                if let index = exerciseToDeleteIndex,
                   workoutViewModel.exercises.indices.contains(index) {
                    workoutViewModel.exercises.remove(at: index)
                    exerciseToDeleteIndex = nil
                }
            }
            Button("No", role: .cancel) {
                exerciseToDeleteIndex = nil
            }
        }
        // Present the Workout Summary view when finishing.
        .sheet(isPresented: $showSummaryView) {
            WorkoutSummaryView(showSummary: $showSummaryView, onContinue: {
                workoutViewModel.endTime = Date()
                workoutViewModel.saveWorkout()
                showWorkoutSheet = false
            }, onReturn: {
                // Return to workout editing.
                showSummaryView = false
            })
            .environmentObject(userViewModel)
            .environmentObject(workoutViewModel)
        }
    }
}
