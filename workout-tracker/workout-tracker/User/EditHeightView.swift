import SwiftUI

struct EditHeightView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var userViewModel: UserViewModel
    @State private var newHeight: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Update Height")) {
                HStack {
                    Text("New Height:")
                    Spacer()
                    HStack {
                        TextField("", text: $newHeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PlainTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text(userViewModel.selectedHeightUnit)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                Button("Save") {
                    if let _ = Double(newHeight), let uid = authViewModel.user?.uid {
                        // Update height in userData dictionary safely
                        var updatedUserData = authViewModel.userData ?? [:]
                        updatedUserData["height"] = newHeight
                        authViewModel.userData = updatedUserData
                        
                        // Call update function
                        userViewModel.updateUserHeight(uid: uid, newHeight: newHeight) { error in
                            if let error = error {
                                alertMessage = "Error updating height: \(error.localizedDescription)"
                                showAlert = true
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            }
                        }
                    } else {
                        alertMessage = "Please enter a valid height."
                        showAlert = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            newHeight = userViewModel.convertHeightToDisplay(height: authViewModel.userData?["height"] as? String ?? "")
        }
        .navigationTitle("Edit Height")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Update Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
