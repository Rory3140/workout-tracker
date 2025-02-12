import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var user: User? = nil
    @Published var userData: [String: Any]? = nil
    @Published var errorMessage: String? = nil

    private var listener: ListenerRegistration? // Firestore snapshot listener
    private let db = Firestore.firestore()

    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil

        // Set up listener if the user is already logged in
        if let user = user {
            addUserDataListener(for: user.uid)
        }
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isAuthenticated = false
                print("Login failed: \(error.localizedDescription)")
                return
            }

            // Successful login
            guard let user = authResult?.user else { return }
            self?.user = user
            self?.isAuthenticated = true
            print("Login successful: \(user.email ?? "")")

            // Add snapshot listener for user data
            self?.addUserDataListener(for: user.uid)
        }
    }

    func register(email: String, password: String, displayName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error as NSError? {
                self?.handleAuthError(error)
                return
            }

            // Successful registration
            guard let user = authResult?.user else { return }

            // Update user profile with displayName
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { [weak self] error in
                if let error = error {
                    print("Failed to set displayName: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to update profile information."
                    return
                }

                // Create Firestore user document
                self?.createFirestoreUserDocument(uid: user.uid, email: email, displayName: displayName)
            }

            self?.user = user
            self?.isAuthenticated = true
            print("Registration successful: \(user.email ?? "")")
            
            // Add snapshot listener for user data
            self?.addUserDataListener(for: user.uid)
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()

            // Clean up user session
            self.user = nil
            self.isAuthenticated = false
            self.userData = nil
            self.errorMessage = nil

            // Remove Firestore listener
            removeUserDataListener()
            print("Logout successful")
        } catch let signOutError as NSError {
            self.errorMessage = signOutError.localizedDescription
            print("Logout failed: \(signOutError.localizedDescription)")
        }
    }

    private func createFirestoreUserDocument(uid: String, email: String, displayName: String) {
        let userData: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "photoURL": "",
            "height": "",
            "weight": "",
            "workouts": [],
            "routines": []
        ]
        
        db.collection("user-data").document(uid).setData(userData) { [weak self] error in
            if let error = error {
                print("Failed to create user document: \(error.localizedDescription)")
                self?.errorMessage = "Failed to save user data."
            } else {
                print("User document created successfully")
            }
        }
    }

    private func addUserDataListener(for uid: String) {
        // Remove any existing listener to prevent duplication
        removeUserDataListener()

        listener = db.collection("user-data").document(uid).addSnapshotListener { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                self?.errorMessage = "Failed to fetch user data."
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                print("User document does not exist")
                self?.userData = nil
                self?.errorMessage = "User data not found."
                return
            }

            self?.userData = data
        }
    }


    private func removeUserDataListener() {
        listener?.remove()
        listener = nil
    }

    private func handleAuthError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.internalError.rawValue:
            self.errorMessage = "Incorrect email or password."
        case AuthErrorCode.invalidEmail.rawValue:
            self.errorMessage = "Invalid email address."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            self.errorMessage = "Email address is already in use."
        case AuthErrorCode.weakPassword.rawValue:
            self.errorMessage = "Password should be at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue:
            self.errorMessage = "Incorrect password."
        default:
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        print("Authentication error: \(self.errorMessage ?? "Unknown error")")
    }
}
