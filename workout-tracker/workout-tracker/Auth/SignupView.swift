import SwiftUI

struct SignupView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var onDismiss: (() -> Void)? = nil

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var displayName: String = ""
    
    // Helper function to validate display names.
    private func isValidDisplayName(_ name: String) -> Bool {
        let regex = "^[A-Za-z0-9_.-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: name)
    }

    var body: some View {
        ZStack {
            // Background gradient.
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Signup card.
                VStack(spacing: 15) {
                    Text("Create an Account")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    TextField("Display Name", text: $displayName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        if !isValidDisplayName(displayName) {
                            authViewModel.errorMessage = "Display name can only contain letters, numbers, underscores, dots, and dashes."
                            return
                        }
                        
                        if password == confirmPassword {
                            authViewModel.register(
                                email: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName,
                                displayName: displayName
                            )
                        } else {
                            authViewModel.errorMessage = "Passwords do not match."
                        }
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .disabled(email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty ||
                              firstName.isEmpty ||
                              lastName.isEmpty ||
                              displayName.isEmpty)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("Sign Up")
            .onReceive(authViewModel.$isAuthenticated) { newValue in
                if newValue {
                    onDismiss?()
                }
            }
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignupView(authViewModel: AuthViewModel(), onDismiss: {})
        }
    }
}
