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

    func updateUserWeight(uid: String, newWeight: String, completion: @escaping (Error?) -> Void) {
        db.collection("user-data").document(uid).updateData([
            "weight": newWeight
        ], completion: completion)
    }
    
    func updateUserHeight(uid: String, newHeight: String, completion: @escaping (Error?) -> Void) {
        db.collection("user-data").document(uid).updateData([
            "height": newHeight
        ], completion: completion)
    }
}
