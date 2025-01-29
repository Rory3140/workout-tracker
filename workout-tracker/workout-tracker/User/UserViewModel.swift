//
//  UserViewModel.swift
//  workout-tracker
//
//  Created by Rory Wood on 28/01/2025.
//

import FirebaseFirestore
import Combine

class UserViewModel: ObservableObject {
    private let db = Firestore.firestore()

    // Add @Published properties if you want to observe changes in the view
    @Published var weight: String = ""

    func updateUserWeight(uid: String, newWeight: String, completion: @escaping (Error?) -> Void) {
        db.collection("user-data").document(uid).updateData([
            "weight": newWeight
        ], completion: completion)
    }

    func addWorkout(uid: String, workout: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("user-data").document(uid).updateData([
            "workouts": FieldValue.arrayUnion([workout])
        ], completion: completion)
    }

    
}
