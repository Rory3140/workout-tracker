import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem { Image(systemName: "house.fill") }
                        .tag(0)
                    
                    WorkoutLogsView()
                        .tabItem { Image(systemName: "square.and.arrow.up") }
                        .tag(1)
                    
                    WorkoutView()
                        .tabItem { Image(systemName: "figure.run") }
                        .tag(2)
                    
                    ProgressView()
                        .tabItem { Image(systemName: "chart.bar.xaxis") }
                        .tag(3)
                    
                    VaultView()
                        .tabItem { Image(systemName: "lock") }
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
        let authViewModel = AuthViewModel()
        authViewModel.isAuthenticated = true
        let userViewModel = UserViewModel()
        let workoutViewModel = WorkoutViewModel()
        
        return NavigationStack {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(userViewModel)
                .environmentObject(workoutViewModel)
        }
    }
}
