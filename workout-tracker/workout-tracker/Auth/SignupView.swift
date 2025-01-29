//
//  SignupView.swift
//  workout-tracker
//
//  Created by Rory Wood on 27/01/2025.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var displayName: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Create an Account")) {
                    TextField("Display Name", text: $displayName)
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                if let errorMessage = authViewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: {
                        if password == confirmPassword {
                            authViewModel.register(email: email, password: password, displayName: displayName)
                        } else {
                            authViewModel.errorMessage = "Passwords do not match."
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Up")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.green)
                    .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || displayName.isEmpty)
                }
            }
            .navigationTitle("Sign Up")
        }
    }
}
