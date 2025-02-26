import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var userViewModel: UserViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // MARK: - Body Metrics Section
            Section(header: Text("Body Metrics")) {
                NavigationLink(destination: EditWeightView(authViewModel: authViewModel, userViewModel: userViewModel)) {
                    HStack {
                        Text("Weight:")
                        Spacer()
                        Text("\(userViewModel.convertWeightToDisplay(weight: userViewModel.userWeight)) \(userViewModel.selectedWeightUnit)")
                            .foregroundColor(.gray)
                    }
                }

                NavigationLink(destination: EditHeightView(authViewModel: authViewModel, userViewModel: userViewModel)) {
                    HStack {
                        Text("Height:")
                        Spacer()
                        Text("\(userViewModel.convertHeightToDisplay(height: userViewModel.userHeight)) \(userViewModel.selectedHeightUnit)")
                            .foregroundColor(.gray)
                    }
                }
            }

            // MARK: - Unit Preferences Section
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
                    .onChange(of: userViewModel.selectedWeightUnit) { _, _ in
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
                    .onChange(of: userViewModel.selectedHeightUnit) { _, _ in
                        userViewModel.updateHeightUnit(newUnit: userViewModel.selectedHeightUnit)
                    }
                }
            }

            // MARK: - Account Section
            Section(header: Text("Account")) {
                HStack {
                    Text("Email:")
                    Spacer()
                    Text(authViewModel.user?.email ?? "Not Available")
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("Display Name:")
                    Spacer()
                    Text(authViewModel.userData?["displayName"] as? String ?? "Not Available")
                        .foregroundColor(.gray)
                }
                
                Button ("Print Local Storage") {
                    print(UserDefaults.standard.dictionaryRepresentation())

                }

                Button("Logout") {
                    authViewModel.logout()
                    dismiss()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
    }
}
