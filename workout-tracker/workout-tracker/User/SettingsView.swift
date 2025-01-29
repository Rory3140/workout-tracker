//
//  SettingsView.swift
//  workout-tracker
//
//  Created by Rory Wood on 28/01/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newWeight: String = ""  // To store the new weight input
    @EnvironmentObject var userViewModel: UserViewModel // Use UserViewModel to handle user data updates
    
    var body: some View {
        List {
            Section(header: Text("Account")) {
                Text("User: \(authViewModel.user?.email ?? "Unknown")")
                
                // Input for changing weight
                HStack {
                    Text("Weight:")
                    Spacer()
                    TextField("Enter weight", text: $newWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }
                
                Button("Update Weight") {
                    // Validate weight input and call update function
                    if let weight = Double(newWeight) {
                        if let uid = authViewModel.user?.uid {
                            userViewModel.updateUserWeight(uid: uid, newWeight: newWeight) { error in
                                if let error = error {
                                    print("Error updating weight: \(error.localizedDescription)")
                                } else {
                                    print("Weight updated successfully")
                                }
                            }
                        }
                    } else {
                        print("Invalid weight input")
                    }
                }
                
                Button("Logout") {
                    authViewModel.logout()
                }
            }
        }
        .navigationTitle("Settings")
    }
}
