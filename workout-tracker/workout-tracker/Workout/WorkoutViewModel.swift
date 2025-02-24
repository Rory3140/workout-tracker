import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Network

class WorkoutViewModel: ObservableObject {
    @Published var userWorkouts: [Workout] = []
    
    @Published var workoutName: String = ""
    @Published var startTime: Date = Date()
    @Published var endTime: Date? = nil
    @Published var workoutDescription: String = ""
    @Published var exercises: [Exercise] = []
    
    private var userViewModel = UserViewModel()
    private let db = Firestore.firestore()
    private var workoutsListener: ListenerRegistration?
    
    private let localWorkoutsKey = "localWorkouts"
    private let monitor = NWPathMonitor()
    
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
    
    init() {
        listenForUserWorkouts()
        monitorNetwork()
        syncOfflineWorkouts()
    }
    
    deinit {
        workoutsListener?.remove()
    }
    
    // MARK: - Offline Sync Methods
    
    private func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection restored")
                self.syncOfflineWorkouts()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func saveWorkoutLocally(_ workout: Workout) {
        var savedWorkouts = loadLocalWorkouts()
        savedWorkouts.append(workout)
        if let data = try? JSONEncoder().encode(savedWorkouts) {
            UserDefaults.standard.set(data, forKey: localWorkoutsKey)
        }
    }
    
    private func loadLocalWorkouts() -> [Workout] {
        guard let data = UserDefaults.standard.data(forKey: localWorkoutsKey),
              let workouts = try? JSONDecoder().decode([Workout].self, from: data) else {
            return []
        }
        return workouts
    }
    
    private func removeLocalWorkout(_ workout: Workout) {
        var savedWorkouts = loadLocalWorkouts()
        savedWorkouts.removeAll { $0.id == workout.id }
        if let data = try? JSONEncoder().encode(savedWorkouts) {
            UserDefaults.standard.set(data, forKey: localWorkoutsKey)
        }
    }
    
    private func syncOfflineWorkouts() {
        let unsyncedWorkouts = loadLocalWorkouts()
        for workout in unsyncedWorkouts {
            uploadWorkoutToFirestore(workout)
        }
    }
    
    // MARK: - Firestore Methods
    
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
        
        saveWorkoutLocally(newWorkout)
        uploadWorkoutToFirestore(newWorkout)
    }
    
    private func uploadWorkoutToFirestore(_ workout: Workout) {
        do {
            let workoutData = try Firestore.Encoder().encode(workout)
            db.collection("workouts").document(workout.id).setData(workoutData) { error in
                if let error = error {
                    print("Error saving workout to Firestore: \(error.localizedDescription)")
                } else {
                    print("Workout successfully saved with ID: \(workout.id)")
                    self.addWorkoutToUser(workoutId: workout.id, userId: workout.createdBy)
                    self.removeLocalWorkout(workout)
                }
            }
        } catch {
            print("Encoding error: \(error.localizedDescription)")
        }
    }
    
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
                self?.userWorkouts = self?.loadLocalWorkouts() ?? []
                return
            }
            
            self?.userWorkouts = self?.loadLocalWorkouts() ?? []
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
                                if !(self?.userWorkouts.contains(where: { $0.id == workout.id }) ?? false) {
                                    self?.userWorkouts.append(workout)
                                }
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
    
    // MARK: - Delete Workouts (Handles Offline Support)
    
    func deleteWorkout(workoutId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        if let localWorkout = loadLocalWorkouts().first(where: { $0.id == workoutId }) {
            removeLocalWorkout(localWorkout)
            userWorkouts.removeAll { $0.id == workoutId }
            print("Workout deleted locally")
            return
        }
        
        let workoutRef = db.collection("workouts").document(workoutId)
        let userRef = db.collection("user-data").document(userId)
        
        workoutRef.delete { error in
            if let error = error {
                print("Error deleting workout: \(error.localizedDescription)")
                return
            }
            
            print("Workout successfully deleted from Firestore")
            userRef.updateData([
                "workouts": FieldValue.arrayRemove([workoutId])
            ]) { error in
                if let error = error {
                    print("Error removing workout ID from user: \(error.localizedDescription)")
                } else {
                    print("Workout ID successfully removed from user's workout list")
                    self.userWorkouts.removeAll { $0.id == workoutId }
                }
            }
        }
    }
    
    // MARK: - Reset Form
    func resetWorkout() {
        workoutName = ""
        startTime = Date()
        endTime = nil
        workoutDescription = ""
        exercises = []
    }
}
