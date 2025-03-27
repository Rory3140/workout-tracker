import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient.
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                    VStack(spacing: 20) {
                        // Login card.
                        VStack(spacing: 15) {
                            Text("Login")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            TextField("Email or Display Name", text: $email)
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
                            
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                authViewModel.login(credential: email, password: password)
                            }) {
                                Text("Login")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                        
                        // Sign Up button.
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Don't have an account? Sign Up")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
//                    .padding(.top, 50)
                
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignupView(authViewModel: authViewModel, onDismiss: { showSignUp = false })
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
