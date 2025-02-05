import SwiftUI

struct WorkoutBottomSheet: View {
    @Binding var showWorkoutSheet: Bool
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var workoutName: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date? = nil
    @State private var workoutDescription: String = ""
    
    @State private var exercises: [Exercise] = []
    
    struct Set: Identifiable {
        var id = UUID()
        var weight: String
        var reps: String
    }
    
    struct Exercise: Identifiable {
        var id = UUID()
        var name: String
        var sets: [Set]
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                List {
                    Section {
                        TextField("Workout Name", text: $workoutName)
                            .keyboardType(.default)
                        
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        if let endTime = endTime {
                            DatePicker("End Time", selection: Binding(
                                get: { endTime },
                                set: { self.endTime = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        } else {
                            Text("End Time: ")
                                .foregroundColor(.gray)
                        }
                        
                        TextField("Workout Description", text: $workoutDescription)
                            .keyboardType(.default)
                    }
                    
                    ForEach(exercises.indices, id: \.self) { index in
                        Section {
                            TextField("Exercise Name", text: $exercises[index].name)
                                .keyboardType(.default)
                            
                            ForEach(exercises[index].sets.indices, id: \.self) { setIndex in
                                HStack {
                                    Text("Set \(setIndex + 1)")
                                        .font(.subheadline)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Weight", text: $exercises[index].sets[setIndex].weight)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 60)
                                    
                                    Text(userViewModel.selectedWeightUnit)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Reps", text: $exercises[index].sets[setIndex].reps)
                                        .keyboardType(.numberPad)
                                        .frame(width: 100)
                                }
                                .padding(.horizontal)
                            }
                            .onDelete { indexSet in
                                exercises[index].sets.remove(atOffsets: indexSet)
                            }
                            
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        exercises[index].sets.append(Set(weight: "", reps: ""))
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
                                        exercises.remove(at: index)
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
                                exercises.append(Exercise(name: "", sets: [Set(weight: "", reps: "")]))
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
                .padding(.vertical)
                
                Button(action: {
                    endTime = Date()
                }) {
                    Text("Finish Workout")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button(action: {
                    showWorkoutSheet = false
                }) {
                    Text("Cancel Workout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }
}
