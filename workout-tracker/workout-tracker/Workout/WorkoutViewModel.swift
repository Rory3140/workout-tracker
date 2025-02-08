import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var startTime: Date = Date()
    @Published var endTime: Date? = nil
    @Published var workoutDescription: String = ""
    @Published var exercises: [Exercise] = []
    
    struct Set: Identifiable, Codable {
        var id = UUID()
        var weight: String
        var reps: String
    }
    
    struct Exercise: Identifiable, Codable {
        var id = UUID()
        var name: String
        var sets: [Set]
    }
    
    struct Workout: Codable {
        var id: String
        var name: String
        var startTime: Date
        var endTime: Date?
        var description: String
        var exercises: [Exercise]
        var createdBy: String
    }
    
    private let db = Firestore.firestore()
    
    /// Saves the workout to the global "workouts" collection and references it in the user's document
    func saveWorkout() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        guard !workoutName.isEmpty else {
            print("Workout name cannot be empty")
            return
        }
        
        let workoutId = UUID().uuidString // Use this as the document ID
        let newWorkout = Workout(
            id: workoutId,
            name: workoutName,
            startTime: startTime,
            endTime: endTime,
            description: workoutDescription,
            exercises: exercises,
            createdBy: userId
        )
        
        do {
            let workoutData = try Firestore.Encoder().encode(newWorkout)
            
            // Save workout in the global "workouts" collection
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
    
    /// Adds the workout ID to the user's "workouts" array
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
    
    /// Resets the workout form after saving
    private func resetWorkout() {
        workoutName = ""
        startTime = Date()
        endTime = nil
        workoutDescription = ""
        exercises = []
    }
}
