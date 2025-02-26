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
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isAuthenticated = false
                print("Login failed: \(error.localizedDescription)")
                return
            }
            guard let user = authResult?.user else { return }
            self?.user = user
            self?.isAuthenticated = true
            print("Login successful: \(user.email ?? "")")
            self?.addUserDataListener(for: user.uid)
            // Notify that the authenticated user has changed
            NotificationCenter.default.post(name: .authUserChanged, object: user.uid)
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String, displayName: String) {
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
                // Create the Firestore document and update isAuthenticated on success.
                self?.createFirestoreUserDocument(uid: user.uid, email: email, firstName: firstName, lastName: lastName, displayName: displayName)
                // Move isAuthenticated update to here if you want to wait for the document.
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
    
    func logout() {
        do {
            try Auth.auth().signOut()
            // Clear in-memory data and local cache
            self.user = nil
            self.isAuthenticated = false
            self.userData = nil
            self.errorMessage = nil
            removeUserDataListener()
            UserDefaults.standard.removeObject(forKey: "userData")
            // Clear cached workouts from previous account
            UserDefaults.standard.removeObject(forKey: "localWorkouts")
            // Notify listeners to clear cached profile picture
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
        let data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "displayName": displayName,
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
    
    // Real-time listener that updates both the UI and local cache, then notifies other view models.
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
