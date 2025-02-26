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

    var body: some View {
        List {
            Section(header: Text("Create an Account")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Display Name", text: $displayName)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
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
                    HStack {
                        Spacer()
                        Text("Sign Up")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(email.isEmpty ||
                          password.isEmpty ||
                          confirmPassword.isEmpty ||
                          firstName.isEmpty ||
                          lastName.isEmpty ||
                          displayName.isEmpty)
            }
        }
        .navigationTitle("Sign Up")
        // Use onReceive instead of onChange
        .onReceive(authViewModel.$isAuthenticated) { newValue in
            if newValue {
                onDismiss?()
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
