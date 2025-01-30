import FirebaseFirestore
import Combine

class UserViewModel: ObservableObject {
    private let db = Firestore.firestore()

    @Published var selectedWeightUnit: String
    @Published var selectedHeightUnit: String

    // Initializer to load from UserDefaults
    init() {
        self.selectedWeightUnit = UserDefaults.standard.string(forKey: "selectedWeightUnit") ?? "kg"
        self.selectedHeightUnit = UserDefaults.standard.string(forKey: "selectedHeightUnit") ?? "cm"
    }

    // Function to convert weight to kg if it's in lbs
    func convertWeightToKg(weight: String) -> String {
        guard let weightValue = Double(weight) else { return weight }
        if selectedWeightUnit == "lbs" {
            let kgValue = weightValue * 0.453592
            return String(format: "%.2f", kgValue)
        }
        return weight
    }

    // Function to convert height to cm if it's in inches
    func convertHeightToCm(height: String) -> String {
        guard let heightValue = Double(height) else { return height }
        if selectedHeightUnit == "inches" {
            let cmValue = heightValue * 2.54
            return String(format: "%.2f", cmValue)
        }
        return height
    }
    
    // Convert weight to lbs if needed and format to 0 decimal places (whole number)
    func convertWeightToDisplay(weight: String) -> String {
        guard let weightValue = Double(weight) else { return weight }
        if selectedWeightUnit == "lbs" {
            let lbsValue = weightValue / 0.453592
            return String(format: "%.0f", lbsValue)
        }
        return String(format: "%.0f", weightValue)
    }


    // Convert height to inches if needed
    func convertHeightToDisplay(height: String) -> String {
        guard let heightValue = Double(height) else { return height }
        if selectedHeightUnit == "inches" {
            let inchesValue = heightValue / 2.54
            return String(format: "%.0f", inchesValue)
        }
        return String(format: "%.0f", heightValue)
    }



    // Update user weight (convert to kg before saving)
    func updateUserWeight(uid: String, newWeight: String, completion: @escaping (Error?) -> Void) {
        let weightInKg = convertWeightToKg(weight: newWeight) // Ensure weight is in kg
        db.collection("user-data").document(uid).updateData([
            "weight": weightInKg
        ], completion: completion)
    }

    // Update user height (convert to cm before saving)
    func updateUserHeight(uid: String, newHeight: String, completion: @escaping (Error?) -> Void) {
        let heightInCm = convertHeightToCm(height: newHeight) // Ensure height is in cm
        db.collection("user-data").document(uid).updateData([
            "height": heightInCm
        ], completion: completion)
    }

    // Update weight unit and save it to UserDefaults
    func updateWeightUnit(newUnit: String) {
        selectedWeightUnit = newUnit
        UserDefaults.standard.set(newUnit, forKey: "selectedWeightUnit") // Save to UserDefaults
    }

    // Update height unit and save it to UserDefaults
    func updateHeightUnit(newUnit: String) {
        selectedHeightUnit = newUnit
        UserDefaults.standard.set(newUnit, forKey: "selectedHeightUnit") // Save to UserDefaults
    }
}
