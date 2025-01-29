//
//  SettingsView.swift
//  workout-tracker
//
//  Created by Rory Wood on 28/01/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        List {
            Section(header: Text("Account")) {
                Text("User: \(authViewModel.user?.email ?? "Unknown")")
                Button("Logout") {
                    authViewModel.logout()
                }
            }
        }
        .navigationTitle("Settings")
    }
}
