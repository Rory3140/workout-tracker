import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit

class UserViewModel: ObservableObject {
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Published Properties
    @Published var selectedWeightUnit: String
    @Published var selectedHeightUnit: String
    @Published var userWeight: String = ""
    @Published var userHeight: String = ""
    // New property to cache user display names.
    @Published var userDisplayNameCache: [String: String] = [:]
    
    // MARK: - Initialization
    init() {
        // Load unit preferences from UserDefaults
        self.selectedWeightUnit = UserDefaults.standard.string(forKey: "selectedWeightUnit") ?? "kg"
        self.selectedHeightUnit = UserDefaults.standard.string(forKey: "selectedHeightUnit") ?? "cm"
        // Weight and height will be updated from Firestore userData
        self.userWeight = ""
        self.userHeight = ""
        
        // Listen for user data updates from AuthViewModel
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUserDataUpdated(_:)),
                                               name: .userDataUpdated,
                                               object: nil)
        // Listen for clear profile picture notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleClearProfilePicture),
                                               name: .clearProfilePicture,
                                               object: nil)
    }
    
    // MARK: - Unit Conversion Methods
    func convertWeightToKg(weight: String) -> String {
        guard let weightValue = Double(weight) else { return weight }
        if selectedWeightUnit == "lbs" {
            let kgValue = weightValue * 0.453592
            return String(format: "%.2f", kgValue)
        }
        return weight
    }
    
    func convertHeightToCm(height: String) -> String {
        guard let heightValue = Double(height) else { return height }
        if selectedHeightUnit == "inches" {
            let cmValue = heightValue * 2.54
            return String(format: "%.2f", cmValue)
        }
        return height
    }
    
    func convertWeightToDisplay(weight: String) -> String {
        guard let weightValue = Double(weight) else { return weight }
        if selectedWeightUnit == "lbs" {
            let lbsValue = weightValue / 0.453592
            return String(format: "%.0f", lbsValue)
        }
        return String(format: "%.0f", weightValue)
    }
    
    func convertHeightToDisplay(height: String) -> String {
        guard let heightValue = Double(height) else { return height }
        if selectedHeightUnit == "inches" {
            let inchesValue = heightValue / 2.54
            return String(format: "%.0f", inchesValue)
        }
        return String(format: "%.0f", heightValue)
    }
    
    // MARK: - Remote Update Methods Only
    func updateUserWeight(uid: String, newWeight: String, completion: @escaping (Error?) -> Void) {
        let weightInKg = convertWeightToKg(weight: newWeight)
        db.collection("user-data").document(uid).updateData(["weight": weightInKg], completion: completion)
    }
    
    func updateUserHeight(uid: String, newHeight: String, completion: @escaping (Error?) -> Void) {
        let heightInCm = convertHeightToCm(height: newHeight)
        db.collection("user-data").document(uid).updateData(["height": heightInCm], completion: completion)
    }
    
    func updateWeightUnit(newUnit: String) {
        selectedWeightUnit = newUnit
        UserDefaults.standard.set(newUnit, forKey: "selectedWeightUnit")
    }
    
    func updateHeightUnit(newUnit: String) {
        selectedHeightUnit = newUnit
        UserDefaults.standard.set(newUnit, forKey: "selectedHeightUnit")
    }
    
    // MARK: - Profile Picture Handling
    func saveProfilePictureLocally(imageData: Data) {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("profile_picture.jpg")
            do {
                try imageData.write(to: fileURL)
            } catch {
                print("Error saving profile picture: \(error.localizedDescription)")
            }
        }
    }
    
    func loadProfilePictureLocally() -> UIImage? {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("profile_picture.jpg")
            if let imageData = try? Data(contentsOf: fileURL) {
                return UIImage(data: imageData)
            }
        }
        return nil
    }
    
    func uploadProfilePicture(uid: String, imageData: Data, completion: @escaping (Bool) -> Void) {
        saveProfilePictureLocally(imageData: imageData)
        let storageRef = storage.reference().child("profile_pictures/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if error != nil {
                completion(false)
                return
            }
            storageRef.downloadURL { url, error in
                if let url = url {
                    self.updateProfilePhotoURL(uid: uid, photoURL: url.absoluteString)
                    completion(true)
                }
            }
        }
    }
    
    private func updateProfilePhotoURL(uid: String, photoURL: String) {
        db.collection("user-data").document(uid).updateData(["photoURL": photoURL])
    }
    
    func profilePictureExists() -> Bool {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("profile_picture.jpg")
            return fileManager.fileExists(atPath: fileURL.path)
        }
        return false
    }
    
    func fetchProfilePicture(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                DispatchQueue.main.async {
                    self.saveProfilePictureLocally(imageData: data)
                }
            }
        }.resume()
    }
    
    func clearProfilePicture() {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("profile_picture.jpg")
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Display Name Fetching
    // Retrieves the display name for a given user ID and caches it.
    // If no display name is found, the userId is returned.
    func getDisplayName(for userId: String, completion: @escaping (String) -> Void) {
        if let cached = userDisplayNameCache[userId] {
            completion(cached)
            return
        }
        db.collection("user-data").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(), let displayName = data["displayName"] as? String {
                DispatchQueue.main.async {
                    self?.userDisplayNameCache[userId] = displayName
                }
                completion(displayName)
            } else {
                completion(userId)
            }
        }
    }
    
    // MARK: - Notification Handlers
    @objc private func handleUserDataUpdated(_ notification: Notification) {
        if let data = notification.object as? [String: Any] {
            self.userWeight = data["weight"] as? String ?? ""
            self.userHeight = data["height"] as? String ?? ""
            if let photoURL = data["photoURL"] as? String, !photoURL.isEmpty {
                if !profilePictureExists() {
                    fetchProfilePicture(from: photoURL)
                }
            }
        }
    }
    
    @objc private func handleClearProfilePicture() {
        clearProfilePicture()
    }
}
