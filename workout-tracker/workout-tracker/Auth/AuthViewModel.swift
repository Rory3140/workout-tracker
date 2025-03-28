import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Extensions
extension Notification.Name {
    static let userDataUpdated = Notification.Name("userDataUpdated")
    static let authUserChanged = Notification.Name("authUserChanged")
    static let clearProfilePicture = Notification.Name("clearProfilePicture")
}

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var user: User? = nil
    @Published var userData: [String: Any]? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Private Properties
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
        
        // Optionally load cached user data
        if let cachedData = UserDefaults.standard.dictionary(forKey: "userData") {
            self.userData = cachedData
        }
        
        if let user = user {
            addUserDataListener(for: user.uid)
        }
    }
    
    // MARK: - Authentication Methods

    /// Log in using either an email or display name (if no "@" is found).
    func login(credential: String, password: String) {
        if credential.contains("@") {
            // Credential appears to be an email.
            Auth.auth().signIn(withEmail: credential, password: password) { [weak self] authResult, error in
                if let error = error as NSError? {
                    self?.handleAuthError(error)
                    self?.isAuthenticated = false
                    print("Login failed: \(self?.errorMessage ?? "Unknown error")")
                    return
                }
                guard let user = authResult?.user else { return }
                self?.user = user
                self?.isAuthenticated = true
                print("Login successful: \(user.email ?? "")")
                self?.addUserDataListener(for: user.uid)
                NotificationCenter.default.post(name: .authUserChanged, object: user.uid)
            }
        } else {
            // Credential is treated as a display name. Query using the lowercased version.
            let lowerCredential = credential.lowercased()
            db.collection("user-data")
                .whereField("displayName_lowercased", isEqualTo: lowerCredential)
                .getDocuments { [weak self] snapshot, error in
                    if let error = error as NSError? {
                        self?.errorMessage = "Error searching for display name: \(error.localizedDescription)"
                        self?.isAuthenticated = false
                        print("Login failed: \(self?.errorMessage ?? "Unknown error")")
                        return
                    }
                    guard let documents = snapshot?.documents, let document = documents.first else {
                        self?.errorMessage = "No account found with that display name."
                        self?.isAuthenticated = false
                        return
                    }
                    let data = document.data()
                    guard let email = data["email"] as? String else {
                        self?.errorMessage = "No email found for this display name."
                        self?.isAuthenticated = false
                        return
                    }
                    // Now sign in using the retrieved email.
                    Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                        if let error = error as NSError? {
                            self?.handleAuthError(error)
                            self?.isAuthenticated = false
                            print("Login failed: \(self?.errorMessage ?? "Unknown error")")
                            return
                        }
                        guard let user = authResult?.user else { return }
                        self?.user = user
                        self?.isAuthenticated = true
                        print("Login successful: \(user.email ?? "")")
                        self?.addUserDataListener(for: user.uid)
                        NotificationCenter.default.post(name: .authUserChanged, object: user.uid)
                    }
                }
        }
    }
    
    /// Registers a new user after verifying that the chosen display name is unique (case-insensitive).
    func register(email: String, password: String, firstName: String, lastName: String, displayName: String) {
        let lowerDisplayName = displayName.lowercased()
        // Check if the display name is unique.
        db.collection("user-data")
            .whereField("displayName_lowercased", isEqualTo: lowerDisplayName)
            .getDocuments { [weak self] snapshot, error in
                if let error = error as NSError? {
                    self?.errorMessage = "Error checking display name uniqueness: \(error.localizedDescription)"
                    return
                }
                if let documents = snapshot?.documents, !documents.isEmpty {
                    self?.errorMessage = "Display name already in use. Please choose another one."
                    return
                }
                // Proceed with registration if display name is unique.
                Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                    if let error = error as NSError? {
                        self?.handleAuthError(error)
                        return
                    }
                    guard let user = authResult?.user else { return }
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges { [weak self] error in
                        if let error = error {
                            print("Failed to set displayName: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to update profile information."
                            return
                        }
                        self?.createFirestoreUserDocument(uid: user.uid, email: email, firstName: firstName, lastName: lastName, displayName: displayName)
                        self?.user = user
                        self?.addUserDataListener(for: user.uid)
                        DispatchQueue.main.async {
                            self?.isAuthenticated = true
                        }
                        print("Registration successful: \(user.email ?? "")")
                        NotificationCenter.default.post(name: .authUserChanged, object: user.uid)
                    }
                }
            }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            self.userData = nil
            self.errorMessage = nil
            removeUserDataListener()
            UserDefaults.standard.removeObject(forKey: "userData")
            UserDefaults.standard.removeObject(forKey: "localWorkouts")
            NotificationCenter.default.post(name: .clearProfilePicture, object: nil)
            NotificationCenter.default.post(name: .authUserChanged, object: nil)
            print("Logout successful")
        } catch let signOutError as NSError {
            self.errorMessage = signOutError.localizedDescription
            print("Logout failed: \(signOutError.localizedDescription)")
        }
    }
    
    // MARK: - Firestore Data Sync
    private func createFirestoreUserDocument(uid: String, email: String, firstName: String, lastName: String, displayName: String) {
        // Store both the original and lowercased display name.
        let data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "displayName": displayName,
            "displayName_lowercased": displayName.lowercased(),
            "email": email,
            "photoURL": "",
            "height": "",
            "weight": "",
            "workouts": [],
            "routines": []
        ]
        db.collection("user-data").document(uid).setData(data) { [weak self] error in
            if let error = error {
                print("Failed to create user document: \(error.localizedDescription)")
                self?.errorMessage = "Failed to save user data."
            } else {
                print("User document created successfully")
            }
        }
    }
    
    private func addUserDataListener(for uid: String) {
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
            UserDefaults.standard.set(data, forKey: "userData")
            NotificationCenter.default.post(name: .userDataUpdated, object: data)
        }
    }
    
    private func removeUserDataListener() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            self.errorMessage = "The email address is invalid. Please check and try again."
        case AuthErrorCode.userNotFound.rawValue:
            self.errorMessage = "No account found with this email. Please sign up or check your email."
        case AuthErrorCode.wrongPassword.rawValue:
            self.errorMessage = "The password is incorrect. Please try again."
        case AuthErrorCode.weakPassword.rawValue:
            self.errorMessage = "The password is too weak. It should be at least 6 characters."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            self.errorMessage = "This email address is already registered. Please log in instead."
        case AuthErrorCode.invalidCredential.rawValue:
            self.errorMessage = "The provided credentials are invalid. Please try again."
        default:
            self.errorMessage = "An unexpected error occurred. Please try again later."
        }
        print("Authentication error: \(self.errorMessage ?? "Unknown error")")
    }
}
