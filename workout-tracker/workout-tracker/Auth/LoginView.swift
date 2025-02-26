import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Login Information")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                }
                
                // Display login error message if available.
                if let errorMessage = authViewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        HStack {
                            Spacer()
                            Text("Login")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                Section {
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Login")
            .navigationDestination(isPresented: $showSignUp) {
                SignupView(
                    authViewModel: authViewModel,
                    onDismiss: { showSignUp = false }
                )
            }
        }
    }
}
