import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationView {
            List {
                // Login Section
                Section(header: Text("Login Information")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                }
                
                // Action Section
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

                // Signup Navigation Link
                Section {
                    NavigationLink(destination: SignupView(
                        authViewModel: authViewModel)
                    ) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Login")
        }
    }
}
