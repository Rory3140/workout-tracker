import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Network

class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userWorkouts: [Workout] = []
    @Published var workoutName: String = ""
    @Published var startTime: Date = Date()
    @Published var endTime: Date? = nil
    @Published var workoutDescription: String = ""
    @Published var exercises: [Exercise] = []

    // MARK: - Private Properties
    private var userViewModel = UserViewModel()
    private let db = Firestore.firestore()
    private var workoutsListener: ListenerRegistration?
    let localWorkoutsKey = "localWorkouts"
    private let monitor = NWPathMonitor()

    // MARK: - Model Structures
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
        var weightUnit: String
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

    // MARK: - Initialization
    init() {
        // Clear previous cached workouts on initialization for a fresh account.
        UserDefaults.standard.removeObject(forKey: localWorkoutsKey)
        userWorkouts = []
        
        // Listen for auth user changes to refresh workouts immediately.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(authUserChanged(_:)),
                                               name: .authUserChanged,
                                               object: nil)
        
        listenForUserWorkouts()
        monitorNetwork()
        syncOfflineWorkouts()
    }
    
    deinit {
        workoutsListener?.remove()
    }
    
    // MARK: - Auth Change Handler
    @objc private func authUserChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.userWorkouts = []
        }
        workoutsListener?.remove()
        workoutsListener = nil
        
        if let userId = notification.object as? String, !userId.isEmpty {
            listenForUserWorkouts()
        }
    }
    
    // MARK: - Network Monitoring & Offline Sync
    private func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.syncOfflineWorkouts()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func saveWorkoutLocally(_ workout: Workout) {
        var savedWorkouts = loadLocalWorkouts()
        if let index = savedWorkouts.firstIndex(where: { $0.id == workout.id }) {
            savedWorkouts[index] = workout
        } else {
            savedWorkouts.append(workout)
        }
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
            resetWorkout()
            return
        }
        guard !workoutName.isEmpty else {
            print("Workout name cannot be empty")
            resetWorkout()
            return
        }
        let workoutId = UUID().uuidString
        let calculatedDuration = endTime != nil ? Calendar.current.dateComponents([.minute], from: startTime, to: endTime!).minute ?? 0 : nil
        
        // Update weights based on stored unit.
        for exerciseIndex in exercises.indices {
            for setIndex in exercises[exerciseIndex].sets.indices {
                if exercises[exerciseIndex].weightUnit == "lbs" {
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
        userWorkouts.append(newWorkout)
        uploadWorkoutToFirestore(newWorkout)
        resetWorkout()
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
            
            var updatedWorkouts = self?.loadLocalWorkouts() ?? []
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
                            if !updatedWorkouts.contains(where: { $0.id == workout.id }) {
                                updatedWorkouts.append(workout)
                            }
                        } catch {
                            print("Error decoding workout \(workoutId): \(error.localizedDescription)")
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self?.userWorkouts = updatedWorkouts.sorted { $0.startTime > $1.startTime }
            }
        }
    }
    
    // MARK: - Delete Workouts
    func deleteWorkout(workoutId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        if let localWorkout = loadLocalWorkouts().first(where: { $0.id == workoutId }) {
            removeLocalWorkout(localWorkout)
            userWorkouts.removeAll { $0.id == workoutId }
            print("Workout deleted locally")
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
    
    // MARK: - Update Workout
    func updateWorkout(_ workout: Workout) {
        // Recalculate duration based on updated start and end times.
        var updatedWorkout = workout
        if let endTime = workout.endTime {
            updatedWorkout.duration = Calendar.current.dateComponents([.minute], from: workout.startTime, to: endTime).minute ?? 0
        } else {
            updatedWorkout.duration = nil
        }
        
        do {
            let workoutData = try Firestore.Encoder().encode(updatedWorkout)
            db.collection("workouts").document(updatedWorkout.id).setData(workoutData) { error in
                if let error = error {
                    print("Error updating workout: \(error.localizedDescription)")
                } else {
                    print("Workout updated successfully")
                    if let index = self.userWorkouts.firstIndex(where: { $0.id == updatedWorkout.id }) {
                        self.userWorkouts[index] = updatedWorkout
                    }
                    self.saveWorkoutLocally(updatedWorkout)
                }
            }
        } catch {
            print("Encoding error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset Workout Form
    func resetWorkout() {
        workoutName = ""
        if userWorkouts.isEmpty {
            startTime = Date()
        }
        endTime = nil
        workoutDescription = ""
        exercises = []
    }
}
