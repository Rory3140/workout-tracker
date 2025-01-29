//
//  EditHeightView.swift
//  workout-tracker
//
//  Created by Rory Wood on 29/01/2025.
//

import SwiftUI

struct EditHeightView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var newHeight: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @Environment(\.presentationMode) var presentationMode  // Allows dismissing the view

    var body: some View {
        List {
            Section(header: Text("Update Height")) {
                HStack {
                    Text("New Height:")
                    Spacer()
                    TextField("Enter height", text: $newHeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }

            Section {
                Button("Save") {
                    if let _ = Double(newHeight), let uid = authViewModel.user?.uid {
                        // Update weight in userData dictionary safely
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
                                    presentationMode.wrappedValue.dismiss() // Go back to SettingsView
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
            newHeight = authViewModel.userData?["height"] as? String ?? ""
        }
        .navigationTitle("Edit Height")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Update Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
