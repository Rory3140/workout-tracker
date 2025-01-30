import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
                        }
                        .tag(0)
                    
                    LogsView()
                        .tabItem {
                            Image(systemName: "square.and.arrow.up")
                            Text("Logs")
                        }
                        .tag(1)
                    
                    WorkoutView()
                        .tabItem {
                            Image(systemName: "figure.run")
                            Text("Workout")
                        }
                        .tag(2)
                    
                    ProgressView()
                        .tabItem {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Progress")
                        }
                        .tag(3)
                    
                    VaultView()
                        .tabItem {
                            Image(systemName: "lock")
                            Text("Vault")
                        }
                        .tag(4)
                }
            } else {
                LoginView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        // Mock or initialize UserViewModel with some state if needed
        let authViewModel = AuthViewModel()
        authViewModel.isAuthenticated = true

        // Initialize UserViewModel and set its preferences, if needed
        let userViewModel = UserViewModel()

//        // Optionally set mock data for UserDefaults or use default values
//        UserDefaults.standard.set("kg", forKey: "selectedWeightUnit") // Set default weight unit
//        UserDefaults.standard.set("cm", forKey: "selectedHeightUnit") // Set default height unit

        return ContentView()
            .environmentObject(authViewModel)
            .environmentObject(userViewModel)
    }
}
