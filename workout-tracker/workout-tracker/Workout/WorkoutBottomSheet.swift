import SwiftUI

struct WorkoutBottomSheet: View {
    @Binding var showWorkoutSheet: Bool
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var showCancelAlert = false
    @State private var showFinishAlert = false
    @State private var showDeleteAlert = false
    @State private var exerciseToDeleteIndex: Int?

    // Define focusable fields.
    enum Field: Hashable {
        case workoutName
        case workoutDescription
        case exerciseName(Int)
        case setWeight(exercise: Int, set: Int)
        case setReps(exercise: Int, set: Int)
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
                
                ScrollViewReader { scrollProxy in
                    List {
                        Section {
                            TextField("Workout Name", text: $workoutViewModel.workoutName)
                                .keyboardType(.default)
                                .focused($focusedField, equals: .workoutName)
                                .id(Field.workoutName)
                            
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
                                            .frame(width: 60, alignment: .leading)
                                        
                                        TextField("Weight", text: $workoutViewModel.exercises[index].sets[setIndex].weight)
                                            .keyboardType(.decimalPad)
                                            .frame(width: 60)
                                            .focused($focusedField, equals: .setWeight(exercise: index, set: setIndex))
                                            .id(Field.setWeight(exercise: index, set: setIndex))
                                        
                                        Text(userViewModel.selectedWeightUnit)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        TextField("Reps", text: $workoutViewModel.exercises[index].sets[setIndex].reps)
                                            .keyboardType(.numberPad)
                                            .frame(width: 100)
                                            .focused($focusedField, equals: .setReps(exercise: index, set: setIndex))
                                            .id(Field.setReps(exercise: index, set: setIndex))
                                    }
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
                        
                        // Use the Add Exercise row as the scroll target.
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    workoutViewModel.exercises.append(
                                        WorkoutViewModel.Exercise(
                                            name: "",
                                            sets: [WorkoutViewModel.Set(weight: "", reps: "")]
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
                        
                        // Determine which anchor to use.
                        let anchor: UnitPoint = {
                            switch newField {
                            case .setWeight(_, _), .setReps(_, _):
                                return .bottom
                            default:
                                return .center
                            }
                        }()
                        
                        // Identify if the new field requires a numeric keyboard.
                        let newIsNumeric: Bool = {
                            switch newField {
                            case .setWeight(_, _), .setReps(_, _):
                                return true
                            default:
                                return false
                            }
                        }()
                        
                        // Check if the previous field was numeric.
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
                        
                        // If switching from a non-numeric to a numeric keyboard, delay the scroll.
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
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                // Move to previous text field.
                Button(action: {
                    let fields = getFocusableFields()
                    if let current = focusedField,
                       let currentIndex = fields.firstIndex(of: current),
                       currentIndex > 0 {
                        focusedField = fields[currentIndex - 1]
                    } else {
                        // Wrap around to the last field.
                        focusedField = fields.last
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                
                // Move to next text field.
                Button(action: {
                    let fields = getFocusableFields()
                    if let current = focusedField,
                       let currentIndex = fields.firstIndex(of: current),
                       currentIndex < fields.count - 1 {
                        focusedField = fields[currentIndex + 1]
                    } else {
                        // Wrap around to the first field.
                        focusedField = fields.first
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
                Spacer()
                Button(action: {
                    // Dismiss the keyboard.
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
        // Cancel Workout Confirmation.
        .alert("Are you sure you want to cancel the workout?", isPresented: $showCancelAlert) {
            Button("Yes", role: .destructive) {
                workoutViewModel.resetWorkout()
                showWorkoutSheet = false
            }
            Button("No", role: .cancel) { }
        }
        // Finish Workout Confirmation.
        .alert("Are you sure you want to finish the workout?", isPresented: $showFinishAlert) {
            Button("Yes", role: .destructive) {
                workoutViewModel.endTime = Date()
                workoutViewModel.saveWorkout()
                showWorkoutSheet = false
            }
            Button("No", role: .cancel) { }
        }
        // Delete Exercise Confirmation.
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
    }
}
