import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var selectedTab = 2
    @State private var showWorkoutSheet = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem { Image(systemName: "person.fill") }
                        .tag(0)
                    
                    WorkoutLogsView()
                        .tabItem { Image(systemName: "square.and.arrow.up") }
                        .tag(1)
                    
                    WorkoutView(showWorkoutSheet: $showWorkoutSheet, workoutViewModel: workoutViewModel)
                        .tabItem { Image(systemName: "dumbbell.fill") }
                        .tag(2)
                    
                    ProgressView()
                        .tabItem { Image(systemName: "chart.bar.xaxis") }
                        .tag(3)
                    
                    VaultView()
                        .tabItem { Image(systemName: "lock") }
                        .tag(4)
                }
                .sheet(isPresented: $showWorkoutSheet) {
                        WorkoutBottomSheet(showWorkoutSheet: $showWorkoutSheet,
                                           workoutViewModel: workoutViewModel)
                            .navigationTitle("Workout Details")
                            .navigationBarTitleDisplayMode(.inline)
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
