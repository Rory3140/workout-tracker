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
                            Text("\(userViewModel.convertWeightToDisplay(weight: authViewModel.userData?["weight"] as? String ?? "")) \(userViewModel.selectedWeightUnit)")

                                .foregroundColor(.gray)
                        }
                    }
                    NavigationLink(destination: EditHeightView()) {
                        HStack {
                            Text("Height:")
                            Spacer()
                            Text("\(userViewModel.convertHeightToDisplay(height: authViewModel.userData?["height"] as? String ?? "")) \(userViewModel.selectedHeightUnit)")
                                .foregroundColor(.gray)
                        }
                    }
                }

                
                Section(header: Text("Unit Preferences")) {
                    HStack {
                        Text("Weight Unit:")
                        Spacer()
                        Picker("", selection: $userViewModel.selectedWeightUnit) {
                            Text("kg").tag("kg")
                            Text("lbs").tag("lbs")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                        .onChange(of: userViewModel.selectedWeightUnit) {
                            userViewModel.updateWeightUnit(newUnit: userViewModel.selectedWeightUnit)
                        }
                    }
                    
                    HStack {
                        Text("Height Unit:")
                        Spacer()
                        Picker("", selection: $userViewModel.selectedHeightUnit) {
                            Text("cm").tag("cm")
                            Text("inches").tag("inches")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                        .onChange(of: userViewModel.selectedHeightUnit) {
                            userViewModel.updateHeightUnit(newUnit: userViewModel.selectedHeightUnit)
                        }
                    }
                }
                
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text(authViewModel.userData?["email"] as? String ?? "")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Display Name:")
                        Spacer()
                        Text(authViewModel.userData?["displayName"] as? String ?? "")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Logout") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
