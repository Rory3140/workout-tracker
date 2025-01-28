//
//  AuthViewModel.swift
//  workout-tracker
//
//  Created by Rory Wood on 27/01/2025.
//

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var user: User? = nil
    @Published var errorMessage: String? = nil

    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Login failed: \(error.localizedDescription)")
                self?.isAuthenticated = false
                return
            }

            // Successful login
            self?.user = authResult?.user
            self?.isAuthenticated = true
            print("Login successful: \(authResult?.user.email ?? "")")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            print("Logout successful")
        } catch let signOutError as NSError {
            self.errorMessage = signOutError.localizedDescription
            print("Logout failed: \(signOutError.localizedDescription)")
        }
    }

    func register(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Registration failed: \(error.localizedDescription)")
                return
            }

            // Successful registration
            self?.user = authResult?.user
            self?.isAuthenticated = true
            print("Registration successful: \(authResult?.user.email ?? "")")
        }
    }
}
