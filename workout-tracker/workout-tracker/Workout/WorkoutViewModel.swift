import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var userWorkouts: [Workout] = []
    
    @Published var workoutName: String = ""
    @Published var startTime: Date = Date()
    @Published var endTime: Date? = nil
    @Published var workoutDescription: String = ""
    @Published var exercises: [Exercise] = []
    
    // Add reference to UserViewModel for unit conversion
    private var userViewModel = UserViewModel()
    
    struct Set: Identifiable, Codable {
        var id = UUID()
        var weight: String
        var reps: String
        var notes: String = ""
    }
    
    struct Exercise: Identifiable, Codable {
        var id = UUID()
        var name: String
        var sets: [Set]
    }
    
    struct Workout: Identifiable, Codable {
        var id: String
        var name: String
        var startTime: Date
        var endTime: Date?
        var duration: Int?
        var description: String
        var exercises: [Exercise]
        var createdBy: String
    }
    
    
    private let db = Firestore.firestore()
    
    // Listener registration property
    private var workoutsListener: ListenerRegistration?
    
    init() {
        listenForUserWorkouts()
    }
    
    /// Sets up a snapshot listener on the user's document.
    func listenForUserWorkouts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        let userRef = db.collection("user-data").document(userId)
        workoutsListener = userRef.addSnapshotListener { [weak self] document, error in
            if let error = error {
                print("Error listening for workouts: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let workoutIds = data["workouts"] as? [String] else {
                print("No workouts found for user.")
                self?.userWorkouts = []
                return
            }
            
            self?.userWorkouts.removeAll()
            let group = DispatchGroup()
            
            for workoutId in workoutIds {
                group.enter()
                self?.db.collection("workouts").document(workoutId).getDocument { workoutDoc, workoutError in
                    if let workoutError = workoutError {
                        print("Error fetching workout \(workoutId): \(workoutError.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    if let workoutData = workoutDoc?.data() {
                        do {
                            let workout = try Firestore.Decoder().decode(Workout.self, from: workoutData)
                            DispatchQueue.main.async {
                                self?.userWorkouts.append(workout)
                            }
                        } catch {
                            print("Error decoding workout \(workoutId): \(error.localizedDescription)")
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self?.userWorkouts.sort { $0.startTime > $1.startTime }
            }
        }
    }
    
    deinit {
        workoutsListener?.remove()
    }
    
    /// Saves the workout to Firestore.
    func saveWorkout() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        guard !workoutName.isEmpty else {
            print("Workout name cannot be empty")
            return
        }
        
        let workoutId = UUID().uuidString
        let calculatedDuration = endTime != nil ? Calendar.current.dateComponents([.minute], from: startTime, to: endTime!).minute ?? 0 : nil
        
        for exerciseIndex in exercises.indices {
            for setIndex in exercises[exerciseIndex].sets.indices {
                if userViewModel.selectedWeightUnit == "lbs" {
                    let convertedWeight = userViewModel.convertWeightToKg(weight: exercises[exerciseIndex].sets[setIndex].weight)
                    exercises[exerciseIndex].sets[setIndex].weight = convertedWeight
                }
            }
        }
        
        let newWorkout = Workout(
            id: workoutId,
            name: workoutName,
            startTime: startTime,
            endTime: endTime,
            duration: calculatedDuration,
            description: workoutDescription,
            exercises: exercises,
            createdBy: userId
        )
        
        do {
            let workoutData = try Firestore.Encoder().encode(newWorkout)
            db.collection("workouts").document(workoutId).setData(workoutData) { error in
                if let error = error {
                    print("Error saving workout: \(error.localizedDescription)")
                } else {
                    print("Workout successfully saved with ID: \(workoutId)")
                    self.addWorkoutToUser(workoutId: workoutId, userId: userId)
                }
            }
        } catch {
            print("Encoding error: \(error.localizedDescription)")
        }
    }
    
    /// Adds the workout ID to the user's document.
    private func addWorkoutToUser(workoutId: String, userId: String) {
        let userRef = db.collection("user-data").document(userId)
        userRef.updateData([
            "workouts": FieldValue.arrayUnion([workoutId])
        ]) { error in
            if let error = error {
                print("Error updating user workouts: \(error.localizedDescription)")
            } else {
                print("Workout ID successfully added to user's workout list")
                self.resetWorkout()
            }
        }
    }
    
    /// Resets the workout form.
    func resetWorkout() {
        workoutName = ""
        startTime = Date()
        endTime = nil
        workoutDescription = ""
        exercises = []
    }
    
    /// Fetches all workouts for the logged-in user.
    func fetchUserWorkouts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        let userRef = db.collection("user-data").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let workoutIds = data["workouts"] as? [String] else {
                print("No workouts found for user.")
                return
            }
            
            self.userWorkouts.removeAll()
            let group = DispatchGroup()
            
            for workoutId in workoutIds {
                group.enter()
                self.db.collection("workouts").document(workoutId).getDocument { workoutDoc, workoutError in
                    if let workoutError = workoutError {
                        print("Error fetching workout \(workoutId): \(workoutError.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    if let workoutData = workoutDoc?.data() {
                        do {
                            let workout = try Firestore.Decoder().decode(Workout.self, from: workoutData)
                            DispatchQueue.main.async {
                                self.userWorkouts.append(workout)
                            }
                        } catch {
                            print("Error decoding workout \(workoutId): \(error.localizedDescription)")
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.userWorkouts.sort { $0.startTime > $1.startTime }
                print("Fetched and sorted user workouts successfully")
            }
        }
    }
    
    /// Deletes a workout from Firestore.
    func deleteWorkout(workoutId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        DispatchQueue.main.async {
            self.userWorkouts.removeAll { $0.id == workoutId }
        }
        
        let workoutRef = db.collection("workouts").document(workoutId)
        let userRef = db.collection("user-data").document(userId)
        
        workoutRef.delete { error in
            if let error = error {
                print("Error deleting workout: \(error.localizedDescription)")
                return
            }
            
            print("Workout successfully deleted")
            userRef.updateData([
                "workouts": FieldValue.arrayRemove([workoutId])
            ]) { error in
                if let error = error {
                    print("Error removing workout ID from user: \(error.localizedDescription)")
                } else {
                    print("Workout ID successfully removed from user's workout list")
                }
            }
        }
    }
}
