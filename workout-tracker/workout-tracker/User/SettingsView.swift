import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        NavigationView {
            List {
                
                Section(header: Text("Body Metrics")) {
                    NavigationLink(destination: EditWeightView()) {
                        HStack {
                            Text("Weight:")
                            Spacer()
                            Text(authViewModel.userData?["weight"] as? String ?? "")
                                .foregroundColor(.gray)
                        }
                    }
                    NavigationLink(destination: EditHeightView()) {
                        HStack {
                            Text("Height:")
                            Spacer()
                            Text(authViewModel.userData?["height"] as? String ?? "")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Account")) {
                    HStack {
                        Text("User:")
                        Spacer()
                        Text(authViewModel.userData?["email"] as? String ?? "")
                            .foregroundColor(.gray)
                    }
                    

                    Button("Logout") {
                        authViewModel.logout()
                    }.foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
