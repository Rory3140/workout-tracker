import SwiftUI

struct EditWeightView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var newWeight: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @Environment(\.presentationMode) var presentationMode  // Allows dismissing the view

    var body: some View {
        List {
            Section(header: Text("Update Weight")) {
                HStack {
                    Text("New Weight:")
                    Spacer()
                    HStack {
                        TextField("", text: $newWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PlainTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text(userViewModel.selectedWeightUnit)
                            .foregroundColor(.gray)
                    }
                }
            }

            Section {
                Button("Save") {
                    if let _ = Double(newWeight), let uid = authViewModel.user?.uid {
                        // Update weight in userData dictionary safely
                        var updatedUserData = authViewModel.userData ?? [:]
                        updatedUserData["weight"] = newWeight
                        authViewModel.userData = updatedUserData
                        
                        // Call update function
                        userViewModel.updateUserWeight(uid: uid, newWeight: newWeight) { error in
                            if let error = error {
                                alertMessage = "Error updating weight: \(error.localizedDescription)"
                                showAlert = true
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    presentationMode.wrappedValue.dismiss() // Go back to SettingsView
                                }
                            }
                        }
                    } else {
                        alertMessage = "Please enter a valid weight."
                        showAlert = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            newWeight = userViewModel.convertWeightToDisplay(weight: authViewModel.userData?["weight"] as? String ?? "")
        }
        .navigationTitle("Edit Weight")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Update Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
