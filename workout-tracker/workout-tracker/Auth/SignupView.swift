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
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            List {
                // Signup Section
                Section(header: Text("Create an Account")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                // Error Message Section
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                // Action Section
                Section {
                    Button(action: {
                        if password == confirmPassword {
                            authViewModel.register(email: email, password: password)
                        } else {
                            errorMessage = "Passwords do not match."
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
                    .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Sign Up")
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView().environmentObject(AuthViewModel())
    }
}
