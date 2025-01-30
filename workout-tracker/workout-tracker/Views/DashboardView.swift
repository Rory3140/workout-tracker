//
//  DashboardView.swift
//  workout-tracker
//
//  Created by Rory Wood on 27/01/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink(destination: SettingsView()){
                    
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}
